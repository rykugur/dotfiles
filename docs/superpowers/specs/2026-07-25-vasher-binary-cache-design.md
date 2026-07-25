# Vasher — Scheduled Prebuilder and LAN Binary Cache

**Date:** 2026-07-25  
**Status:** Approved for implementation  
**Supersedes:** `2026-06-10-vasher-prewarm-cache-design.md`

## Summary

`vasher` is a headless `x86_64-linux` NixOS host that independently prebuilds Jezrien's NixOS closure and exposes retained outputs as a signed Harmonia binary cache on the LAN. It is **not** an SSH remote builder: Jezrien never delegates interactive jobs to it through `nix.buildMachines` or `nix.distributedBuilds`.

Vasher builds every newest `master` revision and, nightly, also creates and validates an updated-lock candidate. A candidate becomes `cache-bump` only after its exact Jezrien closure builds successfully. Jezrien explicitly fast-forwards `master` to that candidate, then switches. Its Nix daemon substitutes matching outputs from Vasher and builds only cache misses.

## Goals

- Replace routine 1–3 hour local compile sessions with cache substitution from a LAN host.
- Keep upstream lock updates reviewable and explicitly promoted by Jezrien's operator.
- Prebuild both lockfile updates and normal configuration/package commits.
- Preserve the last five successful closures through garbage collection.
- Permit a later LXC-to-bare-metal migration without changing client cache configuration or Vasher's service role.

## Non-goals

- SSH remote builds, `nix.buildMachines`, or `nix.distributedBuilds`.
- Automatic `nixos-rebuild switch` on Jezrien.
- GPU-assisted builds or matching Vasher's CPU/GPU vendor to Jezrien.
- Caching Taln (`aarch64-darwin`) or arbitrary development shells.
- WAN access, TLS termination, and failure notifications in v1.

## Architecture

### Vasher host

Vasher is declared in this flake under `modules/hosts/vasher/` as `nixosConfigurations.vasher`. Its host configuration is split by responsibility:

```text
modules/hosts/vasher/
  default.nix          # composes the role with the selected platform
  _role.nix            # scheduler, build user, Harmonia, cache policy, sops
  _platform-lxc.nix    # Proxmox LXC-specific platform configuration
  _seed.nix            # minimal image bootstrap configuration
```

`_role.nix` is platform-independent. It creates a dedicated unprivileged build user, keeps a clone/worktree beneath `/var/lib/vasher`, configures the upstream substituters used by Jezrien, starts Harmonia, and declares the timers, persistent GC roots, and secrets.

The initial platform is an unprivileged Proxmox LXC with nesting enabled, four CPU cores, 8 GiB RAM, and a persistent 100 GiB root filesystem. Vasher requires `x86_64-linux`; its CPU vendor and presence of an AMD GPU are irrelevant. Nix outputs are reusable when their target system and derivation inputs match; a headless Intel or AMD builder can build Jezrien's AMD graphics userspace closure.

### Jezrien client

Jezrien is a cache consumer only. A NixOS module adds these entries to `nix.settings`:

- `http://vasher.local.ryk.sh:5000/` as the first substituter;
- Vasher's dedicated public cache-signing key in `trusted-public-keys`.

Harmonia listens only on the LAN. Its private key is a sops-managed secret readable only by the Harmonia service account. The cache URL and signing key stay stable if the host migrates from LXC to bare metal.

### Secrets

Vasher has two independent secrets, both managed with sops:

- a Git deploy key that can force-update only `cache-bump`;
- a Harmonia cache-signing key.

The signing public key is cleartext client configuration. The deploy key is never present on Jezrien. `cache-bump` is never used to write directly to `master`.

## Build and promotion workflow

### Build current master

A path or periodic trigger detects a new `origin/master` revision. Vasher schedules a build of the newest observed revision:

```text
fetch origin/master
→ reset an isolated worktree to origin/master
→ nix build .#nixosConfigurations.jezrien.config.system.build.toplevel \
    --no-link --print-out-paths
→ on success, create/refresh its GC root
```

This prewarms ordinary configuration and package changes even when `flake.lock` is unchanged. Nix reuses unchanged store paths, so these runs are usually small; they can still be expensive when a commit changes a derivation input.

### Nightly update candidate

A systemd timer runs nightly at 03:00 local time. It uses an isolated worktree reset to the newest `origin/master` and executes:

```text
nix flake update
nix build .#nixosConfigurations.jezrien.config.system.build.toplevel \
  --no-link --print-out-paths
```

On success, it creates a GC root and commits only the generated lockfile change. It force-updates `cache-bump` with `--force-with-lease`. The branch therefore names an exact revision with an exact prebuilt closure. On failure, Vasher records the failure and leaves `cache-bump` at its prior successful revision.

### Jezrien promotion

The operator deliberately promotes a candidate:

```bash
git fetch origin
git merge --ff-only origin/cache-bump
git push origin master
sudo nixos-rebuild switch --flake .#jezrien
```

The merged commit is the exact revision Vasher built. Nix requests matching paths from Harmonia first, then existing public substituters, then performs local builds only for missing paths. The workflow remains safe when the cache is incomplete: a cache miss affects speed, not correctness.

## Concurrency, retention, and failures

A single global lock serializes all Vasher build/publish operations. While one job is active, additional `master` revisions are coalesced into one follow-up build of the newest revision. The nightly candidate job uses the same lock. No build queue is retained.

Each successful job retains its top-level output through a GC-root symlink. Vasher keeps the newest five successful roots, prunes older roots, then runs garbage collection. The 100 GiB root filesystem is the initial capacity target; sustained store usage determines whether storage must grow.

Each job writes `/var/lib/vasher/last-build.json` with revision, candidate status, lock diff summary, start/end timestamps, closure output path, and failure stage. Journal logs are the v1 diagnostic interface.

| Failure | Behavior |
|---|---|
| Fetch/update failure | Record failure; leave cache and `cache-bump` unchanged. |
| Closure evaluation or realisation failure | Record failure; leave cache and `cache-bump` unchanged. |
| Cache-branch lease conflict | Refetch and retry the publish once; otherwise record failure. |
| Harmonia unavailable | Existing retained paths remain intact; client falls through to other substituters or local builds. |

A failed job does not retry in a tight loop. The next trigger retries it.

## Security boundary

Harmonia serves only signed NARs over the LAN. Jezrien trusts Vasher's public signature, so a LAN attacker cannot inject a new store path. The initial service exposes only SSH for administration and Harmonia on TCP 5000 restricted to the LAN interface.

An attacker with Vasher shell access can sign arbitrary outputs; risk is reduced by the minimal service surface, no normal interactive users, hardened SSH, separate service accounts, and sops-protected keys. TLS is not required for path integrity because Nix validates signatures; it may be added later for confidentiality and downgrade resistance.

## Bare-metal migration

The role module remains unchanged. Migration replaces `_platform-lxc.nix` with `_platform-bare.nix`, which imports generated hardware configuration and defines the bare-metal filesystem, bootloader, and networking.

The installer must preserve or restore Vasher's sops age identity and persistent `/nix` storage. With those prerequisites, install the flake's `vasher` configuration on the new host. The cache URL, signing public key, `cache-bump` branch, and Jezrien client configuration remain unchanged. An empty `/nix` store is correct but loses prewarmed artifacts until the next builds complete.

## Verification

Before publishing `cache-bump`, Vasher must observe successful completion of:

```bash
nix build .#nixosConfigurations.jezrien.config.system.build.toplevel \
  --no-link --print-out-paths
```

After promotion, Jezrien must switch to that exact commit and confirm that the requested closure is substituted from `http://vasher.local.ryk.sh:5000/` rather than locally built. Verify cache health with `GET /nix-cache-info` and verify retained store content after garbage collection.

## Implementation acceptance criteria

1. Vasher is evaluated and built as `nixosConfigurations.vasher` from this flake.
2. A normal `master` revision is prebuilt and retained without modifying `cache-bump`.
3. A successful nightly lock update advances `cache-bump` to the exact revision whose Jezrien closure Vasher built.
4. A failed candidate does not change `cache-bump` or remove the last successful cache roots.
5. Jezrien's configuration has Vasher configured solely as a signed substituter; it has no remote-builder configuration.
6. After promoting a successful candidate, Jezrien downloads matching outputs from Vasher and performs no local build for those outputs.
7. Retention leaves exactly the newest five successful closure roots after garbage collection.
8. Replacing the LXC platform module with a bare-metal platform module requires no change to the role module or Jezrien cache client configuration.
