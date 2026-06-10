# Vasher — Pre-Warming Binary Cache LXC

**Date:** 2026-06-10
**Status:** Draft for review

## Summary

A new NixOS LXC (`vasher`) running on Proxmox that nightly:

1. pulls the dotfiles flake,
2. runs `nix flake update`,
3. builds `nixosConfigurations.jezrien.config.system.build.toplevel`,
4. on success, force-pushes the updated `flake.lock` to a `cache-bump` branch,
5. serves its `/nix/store` to jezrien over LAN via harmonia, signed with a per-LXC key.

The weekly desktop rebuild flow on jezrien becomes: `git merge --ff-only origin/cache-bump && sudo nixos-rebuild switch --flake .#jezrien`, with cache hits on the entire closure.

Vasher is managed in this same flake as a new host, so its config is reproducible and auditable. The provisioning path uses `nixos-generators` to produce a Proxmox LXC rootfs tarball, with a bootstrap script wrapping `pct create`. Vasher's role config is decoupled from its hosting (LXC today) so it can migrate to bare metal later with a one-line module swap.

## Goals

- Zero local builds on jezrien for the typical weekly rebuild flow.
- Fully reproducible: any single Proxmox node + this flake reproduces vasher from scratch.
- Bounded disk usage on the LXC (~100GB).
- No PR ceremony for routine lock updates; just `git merge`.
- A clear migration path to bare-metal hosting later.

## Non-goals

- Caching for taln (aarch64-darwin) — wrong arch for x86_64 LXC.
- Caching dev shells or arbitrary custom packages beyond what jezrien's closure pulls in (can be added later).
- Off-LAN access (no Tailscale/WAN exposure in v1).
- Real-time alerting on build failure (journal-only in v1).
- Cross-architecture builds.

## Components

| # | Component | Lives at | Purpose |
|---|-----------|----------|---------|
| 1 | LXC image | `packages.x86_64-linux.vasher-lxc-image` (flake output, produced by `nixos-generators`) | Bake a Proxmox CT rootfs tarball with minimal seed config |
| 2 | Proxmox CT bootstrap | `scripts/bootstrap/proxmox-lxc-create.sh` | Wrap `pct create` with our chosen CT ID, resources, network |
| 3 | Vasher host config | `modules/hosts/vasher/` | Compose role + platform; declares `nixosConfigurations.vasher` |
| 4 | Build timer + service | `modules/nixos/swoleflake-prebuild.nix` | Nightly flake update + build + push. The `ExecStart` is a `pkgs.writeShellApplication` so the script gets `shellcheck`-validated at module build time |
| 5 | Harmonia substituter | `modules/nixos/harmonia-cache.nix` | Sign and serve `/nix/store` over HTTP |
| 6 | GC roots + collection | (part of `swoleflake-prebuild.nix`) | Keep last 5 successful builds; prune the rest |
| 7 | Jezrien client config | `modules/nixos/cache-substituter.nix` | Opt-in module adding vasher as substituter + trusted key |
| 8 | Secrets | `sops/secrets.yaml` (vasher's host secrets) | Deploy SSH key + harmonia signing key |

## Module organization (dendritic pattern)

```
modules/
  hosts/
    vasher/
      default.nix          # imports _role + _platform-lxc; registers nixosConfigurations.vasher
      _role.nix            # WHAT vasher does (platform-agnostic):
                           #   - hostname, swoleflake user, sops layout
                           #   - imports swoleflake-prebuild + harmonia-cache modules
      _platform-lxc.nix    # HOW vasher is hosted today:
                           #   - imports nixpkgs/.../proxmox-lxc.nix
                           #   - boot.isContainer = true; no kernel/initrd; lxc-specific tweaks
      _seed.nix            # used ONLY when baking the image; not imported at runtime
  nixos/
    swoleflake-prebuild.nix   # NEW: timer + service + gcroot rotation script
    harmonia-cache.nix        # NEW: wraps services.harmonia (port, signKeyPaths, firewall)
    cache-substituter.nix     # NEW: client opt-in (jezrien imports this)
```

Vasher migrating to bare metal later means:

1. Generate `hardware-configuration.nix` on the bare-metal host.
2. Add `modules/hosts/vasher/_platform-bare.nix` importing that + bootloader + filesystem.
3. In `default.nix`, swap `_platform-lxc.nix` for `_platform-bare.nix` (one-line change).
4. Re-encrypt or restore vasher's sops age key.
5. `nixos-install --flake .#vasher`.

The substituter hostname stays the same; jezrien's config doesn't change.

## Data flow

### Nightly on vasher

```
[systemd.timers.swoleflake-prebuild fires ~3am]
  └─ swoleflake-prebuild.service (runs as `swoleflake` user)
      ├─ cd /var/lib/swoleflake
      ├─ git fetch origin                          [exit 10 on failure]
      ├─ git checkout master && git reset --hard origin/master
      ├─ nix flake update                          # writes new flake.lock locally
      ├─ nix build .#nixosConfigurations.jezrien.config.system.build.toplevel \
      │            --no-link --print-out-paths     [exit 20 eval / 30 realisation]
      │
      ├─ success:
      │   ├─ ln -sf <out> /var/lib/swoleflake/gcroots/$(date +%s)-jezrien
      │   ├─ prune gcroots older than 5 newest
      │   ├─ nix-collect-garbage
      │   ├─ write /var/lib/swoleflake/last-build.json (status, timing, lock diff summary)
      │   ├─ git add flake.lock
      │   ├─ git commit -m "chore: nightly flake.lock update ($(date -I))"
      │   └─ git push --force-with-lease origin HEAD:cache-bump  [exit 40, retry once]
      │
      └─ failure:
          ├─ write last-build.json with status=failed
          └─ exit non-zero (cache-bump untouched; substituter still serves previous build)
```

### Continuously on vasher

`services.harmonia` serves `/nix/store` on port 5000, signing with `vasher.swoleflake-1`.

### Weekly on jezrien

```
git fetch origin
git merge --ff-only origin/cache-bump
sudo nixos-rebuild switch --flake .#jezrien
  └─ Nix consults substituters in order:
     1. http://vasher.lan:5000 (signed by trusted key vasher.swoleflake-1) → cache hits
     2. cache.nixos.org / hyprland / etc. (fallback for paths vasher didn't build)
     3. local build (last resort)
```

### Edge cases

- **User commits to master between LXC runs:** next run picks it up, builds master+new lock, pushes cache-bump including the user's commit. Weekly merge sees both.
- **User commits to master, wants to rebuild immediately:** cache-bump is stale relative to user's new commit; local rebuild may compile some new paths; unchanged inputs still cache-hit.
- **Build fails (broken upstream input):** cache-bump not advanced; user can rebuild from master + previous good lock by not merging cache-bump that week; LXC retries next night.
- **User manually runs `nix flake update` on desktop:** desktop's lock diverges from cache-bump; rebuild may miss cache for changed inputs. Solvable by pushing the lock update so LXC catches up.
- **Force-push race:** `--force-with-lease` aborts if cache-bump moved unexpectedly; retried once per run.

## Error handling

| Failure | Exit code (log clarity only) | Behavior |
|---|---|---|
| `git fetch` failure | 10 | Skip run; retry next night |
| `nix flake update` no diff | 0 (log "no changes") | Continue — master may still warrant a rebuild |
| `nix build` eval failure | 20 | Skip; user's commit is at fault |
| `nix build` realisation failure | 30 | Skip; upstream at fault |
| `git push` race (lease lost) | 40 | Refetch + retry once in-script |

systemd treats all non-zero exits as failure; exit codes exist only to make the journal readable. No retry loop inside the service; daily cadence absorbs transient breakage.

## Observability

- `journalctl -u swoleflake-prebuild` — primary surface.
- `/var/lib/swoleflake/last-build.json` — last run summary: `{ status, started_at, finished_at, lock_diff_summary, build_size_bytes, exit_code }`.
- `curl http://vasher.lan:5000/nix-cache-info` — harmonia health check.
- **No alerting in v1.** If something fails for a week, the user notices when the weekly rebuild starts compiling locally. `OnFailure=swoleflake-notify.service` is a future addition.

## Security & trust

### Trust model

One-way: jezrien trusts vasher to vouch for store paths via the public-key signature on each NAR. Vasher does not authenticate jezrien; signatures are what makes paths safe. Same model as cache.nixos.org.

### Signing key

- Generated on vasher's first boot: `nix-store --generate-binary-cache-key vasher.swoleflake-1 sec.key pub.key`.
- Private: `sops.secrets."swoleflake/harmonia_signing_key"`, mode 0400, owner `harmonia`.
- Public: cleartext in `modules/nixos/cache-substituter.nix`.
- Versioned name (`-1`) supports rotation by adding `-2` alongside, then removing `-1` after one full cycle.

### Deploy key (push to `cache-bump`)

- Separate ed25519 keypair.
- Public half: GitHub deploy key with write access on this repo.
- Private half: `sops.secrets."swoleflake/deploy_key"`, mode 0400, owner `swoleflake`.
- Service uses `GIT_SSH_COMMAND="ssh -i /run/secrets/swoleflake/deploy_key -o IdentitiesOnly=yes"`.
- Branch protection (where available) restricts the deploy key to `cache-bump` only; otherwise risk is bounded because pushes to master would be immediately visible.

### sops layout

```yaml
swoleflake:
  deploy_key: |
    -----BEGIN OPENSSH PRIVATE KEY-----
    ...
  harmonia_signing_key: |
    vasher.swoleflake-1:<base64 priv>
```

`.sops.yaml` gains vasher's age key alongside the user key as recipient.

### Jezrien trust config

```nix
# modules/nixos/cache-substituter.nix
{ config, lib, ... }:
{
  options.swoleflake.cache.enable =
    lib.mkEnableOption "trust the swoleflake (vasher) substituter";

  config = lib.mkIf config.swoleflake.cache.enable {
    nix.settings = {
      substituters = [ "http://vasher.lan:5000/" ];
      trusted-public-keys = [ "vasher.swoleflake-1:<pubkey base64>" ];
    };
  };
}
```

Jezrien's host config flips `swoleflake.cache.enable = true;`.

### Network surface vasher exposes

- TCP 5000 (harmonia) — LAN-only via `networking.firewall.interfaces.<lan>.allowedTCPPorts`.
- TCP 22 (sshd) — admin only.
- Nothing else.

### Attack scenarios

| Scenario | Mitigation |
|---|---|
| LAN attacker poisons harmonia response | Needs vasher's signing key; sops-encrypted, only readable by harmonia user |
| Shell access to vasher | Can sign arbitrary paths; mitigation: no user accounts, hardened sshd, minimal service surface |
| Deploy key leak | Attacker can force-push `cache-bump`; user notices odd merge diff; rotate via sops + GitHub |
| Upstream nixpkgs backdoor | Out of scope; same risk as today without vasher |
| LAN MITM of `http://vasher.lan:5000` | Signatures still validate; attacker can downgrade to older signed paths but not inject. TLS via Caddy reverse proxy is a future option |

### Rotation playbook

- **Signing key:** `nix-store --generate-binary-cache-key vasher.swoleflake-2 ...`; add new private to sops; add `-2` pubkey alongside `-1` in `cache-substituter.nix`; deploy; after one full cache-bump cycle, remove `-1`.
- **Deploy key:** generate new pair; replace in sops; update GitHub deploy keys; deploy.

## Upstream substituters on vasher

Vasher itself must trust and use the same upstream caches jezrien does — otherwise vasher rebuilds hyprland, mesa_git, nix-gaming, etc. from source, defeating the purpose. The flake's `nixConfig.extra-substituters` only applies for trusted users; vasher's system-level `nix.settings.substituters` must explicitly include:

- `cache.nixos.org` (default)
- `hyprland.cachix.org`
- `nix-gaming.cachix.org`
- `nix-citizen.cachix.org`
- `helix.cachix.org`
- `pi.cachix.org`
- `nyx-cache.chaotic.cx`

With matching `trusted-public-keys`. This is the same list already in `flake.nix`'s `nixConfig`, just hoisted into vasher's NixOS config so the `swoleflake` build user can use them.

## Storage & GC

- CT sized at ~100GB rootfs.
- Last 5 successful builds kept as gcroot symlinks in `/var/lib/swoleflake/gcroots/`.
- `nix.gc.automatic = true` after each build prunes unprotected paths.
- Expected steady state: `du -sh /nix/store` around 30-60GB; headroom for transient build artifacts.

## Image build + provisioning

### Build the rootfs

Add `nixos-generators` as a flake input:

```nix
nixos-generators = {
  url = "github:nix-community/nixos-generators";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

Expose a flake output:

```nix
packages.x86_64-linux.vasher-lxc-image = inputs.nixos-generators.nixosGenerate {
  inherit pkgs;
  format = "proxmox-lxc";
  modules = [ ./modules/hosts/vasher/_seed.nix ];
};
```

`_seed.nix` is minimal: hostname, sshd enabled, root authorized key, dhcp on `eth0`, nix flakes enabled. Just enough to reach the box and run `nixos-rebuild`.

### Bootstrap flow

```bash
# On dev machine
nix build .#vasher-lxc-image
scp result/tarball/*.tar.xz proxmox:/var/lib/vz/template/cache/

# On Proxmox (or via `scripts/bootstrap/proxmox-lxc-create.sh`)
pct create 200 local:vztmpl/<filename>.tar.xz \
  --hostname vasher \
  --cores 4 --memory 8192 \
  --rootfs local-lvm:100 \
  --net0 name=eth0,bridge=vmbr0,ip=dhcp \
  --features nesting=1 \
  --unprivileged 1 \
  --ssh-public-keys ~/.ssh/authorized_keys
pct start 200

# Once SSH reachable
ssh root@vasher.lan "nixos-rebuild switch --flake github:rykugur/dotfiles#vasher"
```

After first `nixos-rebuild`, timer, harmonia, secrets, and gcroot logic are all live. Re-running the seed flow is only needed on CT destruction.

## Open questions

- LXC CT ID on the Proxmox host (200? something else from the existing range?). Resolve during implementation.
- Exact LAN hostname (`vasher.lan` vs `vasher.<existing-domain>`). Resolve during implementation; depends on existing DNS/mDNS setup.
- Whether to clean up the stale `nixy` reference in `flake.nix` as part of this work, or in a follow-up. (Trivial either way.)

## Out of scope (future work)

- Failure notifications (ntfy/email via `OnFailure=`).
- TLS termination on harmonia (Caddy reverse proxy).
- Caching dev shells, custom packages beyond jezrien's closure.
- Taln darwin caching (would require a darwin builder, not an LXC).
- Tailscale-based off-LAN access.
- PR-based workflow for the lock bump (vs the current branch-only model).
