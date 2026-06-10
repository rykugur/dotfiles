# Vasher Pre-Warming Binary Cache LXC — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Stand up `vasher`, a NixOS LXC on Proxmox that nightly builds jezrien's system closure, force-pushes the updated `flake.lock` to a `cache-bump` branch, and serves its `/nix/store` over LAN via harmonia so jezrien's weekly rebuilds hit cache instead of building locally.

**Architecture:** New host in this flake (dendritic pattern). Host config split into platform-agnostic role + LXC-specific platform module so bare-metal migration later is a one-line swap. Build/push driven by a systemd timer running a `pkgs.writeShellApplication`. Secrets (deploy SSH key + harmonia signing key) managed via existing sops-nix setup. Jezrien gets an opt-in client module adding vasher as substituter + trusted public key.

**Tech Stack:** NixOS, flake-parts (dendritic), `nixos-generators` (proxmox-lxc format), `services.harmonia`, `sops-nix`, systemd timers, ed25519 SSH keys, Proxmox CT (LXC).

**Spec:** `docs/superpowers/specs/2026-06-10-vasher-prewarm-cache-design.md`

---

## TDD approach for NixOS configuration

NixOS configuration is declarative — there's no traditional unit-test scaffolding for a module that wires `services.harmonia`. The pragmatic verifications used throughout this plan are:

1. **Eval test:** `nix flake check` — validates every output evaluates and types check.
2. **Build test:** `nix build .#nixosConfigurations.<host>.config.system.build.toplevel --no-link --print-out-paths` — confirms the system fully realises.
3. **Runtime smoke test:** Deploy to the actual host; `systemctl status <unit>`, `journalctl -u <unit>`, `curl http://vasher.lan:5000/nix-cache-info`, `nix-store --verify-store --check-contents` — observed behavior.

Each task ends with one or more of these verifications before commit. Treat them with the same discipline you'd treat unit tests: if verification fails, don't proceed to commit.

---

## Phase 0 — Scaffolding

Three small prep tasks that touch the flake structure but don't deploy anything yet.

### Task 0.1: Add `nixos-generators` flake input

**Files:**
- Modify: `flake.nix`

- [ ] **Step 1: Read the current `inputs` block** to find a clean place to add the new input (probably after `import-tree` or in the "nix/flake stuff" group).

- [ ] **Step 2: Add the input**

Insert into the `inputs = { ... }` block:

```nix
nixos-generators = {
  url = "github:nix-community/nixos-generators";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

- [ ] **Step 3: Verify the flake still evaluates**

Run: `nix flake check 2>&1 | head -20`
Expected: no eval errors (warnings about missing system are acceptable; we'll fix in later tasks).

- [ ] **Step 4: Commit**

```bash
git add flake.nix flake.lock
git commit -m "feat(flake): add nixos-generators input for vasher LXC image"
```

### Task 0.2: Remove stale `nixy` reference from `flake.nix`

**Files:**
- Modify: `flake.nix`

Background: `nixy` was a historical NixOS LXC test container that doesn't exist anymore. The spec's brainstorming surfaced that `flake.nix` still has stale references that should be cleaned up so vasher isn't introduced into a half-broken state.

- [ ] **Step 1: Search for any `nixy` reference in `flake.nix`**

Run: `grep -n nixy flake.nix`
If no matches, skip this task entirely (recheck the file in case stale doc references are elsewhere; commit the no-op skip is fine, just skip to Task 0.3).

- [ ] **Step 2: Remove the reference**

If a reference exists in `nixosConfigurations` or elsewhere, delete the offending lines. Don't touch anything else.

- [ ] **Step 3: Verify**

Run: `nix flake check 2>&1 | head -20`
Expected: clean eval (same as before).

- [ ] **Step 4: Commit**

```bash
git add flake.nix
git commit -m "chore(flake): drop stale nixy reference"
```

### Task 0.3: Add `vasher` age key to `.sops.yaml`

**Files:**
- Modify: `.sops.yaml`

Background: vasher needs its own age key to decrypt its system secrets. We declare a placeholder now; the real key is generated on vasher's first boot (Task 3.1) and inserted before secrets are encrypted.

- [ ] **Step 1: Generate a vasher age key locally for now**

Run:
```bash
nix-shell -p age --run 'age-keygen -o /tmp/vasher-age.txt'
grep "public key" /tmp/vasher-age.txt
```

Copy the public key (`age1...`) for the next step. **Keep `/tmp/vasher-age.txt`** — you'll deploy the private half to vasher in Task 2.2.

- [ ] **Step 2: Add to `.sops.yaml`**

Modify the `&hosts:` anchor list and add a `creation_rules` entry:

```yaml
keys:
  - &hosts:
    - &jezrien age1zrsq6443zacdx3tpsfryeg2t5wqxz465cxezmar4qu8zgh00v5fsc8vypu
    - &taln age1kah7ss6eay00u8j95lul79u2rkfqml5r9fe7jetemlhhrvpztfrs6gvz85
    - &taldain age10qrd4ws96e6wd6gtel3pp99mhw4k6gpf9q6st8wp6yk0v7hsvewqpg063k
    - &homelab age1y4rkzxjql65p2vl68dy73ly0ga864u287mur9l60m4xspucj353q276ss0
    - &work-macbook age1a2dsa5sk4xnl8m8vdahhl0h7v54n89nzp4jesuk0mn79ck4ukdjsjuyuax
    - &vasher <PASTE-PUBLIC-KEY-HERE>

creation_rules:
  # ... existing entries unchanged ...
  - path_regex: vasher/secrets.yaml$
    key_groups:
      - age:
          - *dusty
          - *vasher
```

- [ ] **Step 3: Verify YAML parses**

Run: `nix-shell -p yq --run 'yq . .sops.yaml > /dev/null'`
Expected: no errors.

- [ ] **Step 4: Commit**

```bash
git add .sops.yaml
git commit -m "feat(sops): add vasher age key recipient"
```

---

## Phase 1 — Vasher host modules + image build

Goal of this phase: `nix build .#nixosConfigurations.vasher.config.system.build.toplevel` succeeds AND `nix build .#vasher-lxc-image` produces a Proxmox-uploadable tarball. We're not deploying anything yet — just declaring the host and proving the closure is buildable.

### Task 1.1: Create vasher's seed config

**Files:**
- Create: `modules/hosts/vasher/_seed.nix`

The seed config is **only** used by `nixos-generators` to bake the initial CT image. It's NOT imported by the runtime `nixosConfigurations.vasher`. After the LXC boots, `nixos-rebuild switch --flake .#vasher` swaps everything for the real config. Therefore the seed must be minimal — just enough for sshd + DHCP + flakes.

- [ ] **Step 1: Create the file**

```nix
# modules/hosts/vasher/_seed.nix
# Used ONLY by nixos-generators to bake the initial Proxmox LXC image.
# After first boot, `nixos-rebuild switch --flake .#vasher` replaces this entirely.
{ modulesPath, ... }:
{
  imports = [ "${modulesPath}/virtualisation/proxmox-lxc.nix" ];

  networking = {
    hostName = "vasher";
    useDHCP = true;
    firewall.enable = true;
  };

  time.timeZone = "America/Chicago";

  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    trusted-users = [ "root" ];
  };

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "prohibit-password";
      PasswordAuthentication = false;
    };
  };

  users.users.root.openssh.authorizedKeys.keys = [
    # personal key from modules/misc/ssh.nix; keep in sync if rotated
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAgLk3xlBbjNte2VW4ZE6ewngB07bZ1MdkOBnJFFnzQV"
  ];

  environment.systemPackages = [ ];

  system.stateVersion = "24.11";
}
```

- [ ] **Step 2: Syntax-check the file**

Run: `nix-instantiate --parse modules/hosts/vasher/_seed.nix > /dev/null`
Expected: no error (Nix successfully parses the expression). Full semantic verification happens when the image builds in Task 1.5.

- [ ] **Step 3: Commit**

```bash
git add modules/hosts/vasher/_seed.nix
git commit -m "feat(hosts/vasher): add minimal seed config for LXC image bake"
```

### Task 1.2: Create vasher's LXC platform module

**Files:**
- Create: `modules/hosts/vasher/_platform-lxc.nix`

This file holds *only* the "vasher is hosted as an LXC" configuration. When we migrate to bare metal later, we swap this for `_platform-bare.nix`.

- [ ] **Step 1: Create the file**

```nix
# modules/hosts/vasher/_platform-lxc.nix
# HOW vasher is hosted: Proxmox LXC. Swap this file for _platform-bare.nix when
# migrating to bare metal.
{ modulesPath, lib, ... }:
{
  imports = [ "${modulesPath}/virtualisation/proxmox-lxc.nix" ];

  # LXC container specifics: no kernel, no initrd, no bootloader.
  boot.isContainer = true;
  boot.loader.grub.enable = lib.mkForce false;
  boot.loader.systemd-boot.enable = lib.mkForce false;

  # The CT rootfs is mounted by Proxmox; NixOS doesn't manage filesystems.
  fileSystems = lib.mkForce { };

  # Let proxmox-lxc set up the rest of the LXC integration (cgroup, console, etc.).
  proxmoxLXC.manageNetwork = false; # let proxmox/dhcp handle eth0
  proxmoxLXC.privileged = false;
}
```

- [ ] **Step 2: Syntax-check the file**

Run: `nix-instantiate --parse modules/hosts/vasher/_platform-lxc.nix > /dev/null`
Expected: no error. Full semantic verification happens in Task 1.4 when the host wires the module up.

- [ ] **Step 3: Commit**

```bash
git add modules/hosts/vasher/_platform-lxc.nix
git commit -m "feat(hosts/vasher): add Proxmox LXC platform module"
```

### Task 1.3: Create vasher's role module

**Files:**
- Create: `modules/hosts/vasher/_role.nix`

This is "what vasher does" — platform-agnostic. For Phase 1, it's just the identity bits: hostname, system swoleflake user, basic sshd, basic system packages. Harmonia and the prebuild service come in Phase 3.

- [ ] **Step 1: Create the file**

```nix
# modules/hosts/vasher/_role.nix
# WHAT vasher does. Platform-agnostic — works on LXC or bare metal.
{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
{
  imports = [ inputs.sops-nix.nixosModules.sops ];

  networking.hostName = "vasher";

  time.timeZone = "America/Chicago";

  i18n.defaultLocale = "en_US.UTF-8";

  nix.settings = {
    experimental-features = [ "nix-command" "flakes" "pipe-operators" ];
    trusted-users = [ "root" "swoleflake" ];
    auto-optimise-store = true;
  };

  # Unprivileged build-bot user. No home directory needed for activation;
  # the prebuild service creates /var/lib/swoleflake.
  users.users.swoleflake = {
    isSystemUser = true;
    group = "swoleflake";
    home = "/var/lib/swoleflake";
    createHome = true;
    shell = pkgs.bashInteractive; # so `sudo -u swoleflake` is debuggable
  };
  users.groups.swoleflake = { };

  # Minimal admin SSH access (no `dusty` user on vasher).
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "prohibit-password";
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAgLk3xlBbjNte2VW4ZE6ewngB07bZ1MdkOBnJFFnzQV"
  ];

  # System secrets for vasher.
  sops = {
    defaultSopsFile = ./secrets.yaml;
    age.keyFile = "/var/lib/sops-nix/key.txt";
  };

  environment.systemPackages = with pkgs; [
    git
    htop
    jq
    neovim
  ];

  networking.firewall.enable = true;

  system.stateVersion = "24.11";
}
```

- [ ] **Step 2: Commit**

```bash
git add modules/hosts/vasher/_role.nix
git commit -m "feat(hosts/vasher): add platform-agnostic role module"
```

### Task 1.4: Wire vasher into `nixosConfigurations`

**Files:**
- Create: `modules/hosts/vasher/default.nix`
- Create: `modules/hosts/vasher/secrets.yaml` (empty placeholder; encrypted real content lands in Task 3.1)

- [ ] **Step 1: Create the placeholder secrets file**

Run:
```bash
mkdir -p modules/hosts/vasher
cat > modules/hosts/vasher/secrets.yaml <<'EOF'
# This file will be populated by sops in Task 3.1. Until then it's a
# placeholder so the module imports succeed. The defaultSopsFile in
# _role.nix points here; if a module attempts to read a secret from it
# before Task 3.1, eval will fail.
{}
EOF
```

- [ ] **Step 2: Create the host's `default.nix`**

```nix
# modules/hosts/vasher/default.nix
# Vasher — NixOS LXC binary-cache pre-warmer (x86_64-linux)
{ inputs, ... }:
{
  flake.nixosConfigurations.vasher = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = [
      ./_role.nix
      ./_platform-lxc.nix
    ];
    specialArgs = {
      inherit inputs;
      outputs = inputs.self;
      hostname = "vasher";
    };
  };
}
```

(Note: vasher doesn't take `username` as a specialArg because no `dusty` user exists on it.)

- [ ] **Step 3: Verify the host evaluates**

Run:
```bash
nix eval .#nixosConfigurations.vasher.config.networking.hostName 2>&1
```
Expected: `"vasher"`.

- [ ] **Step 4: Verify the closure builds**

Run:
```bash
nix build .#nixosConfigurations.vasher.config.system.build.toplevel --no-link --print-out-paths 2>&1 | tail -5
```
Expected: prints an `/nix/store/...-nixos-system-vasher-...` path. First run may take time.

- [ ] **Step 5: Commit**

```bash
git add modules/hosts/vasher/default.nix modules/hosts/vasher/secrets.yaml
git commit -m "feat(hosts/vasher): register nixosConfigurations.vasher"
```

### Task 1.5: Expose the LXC image as a flake package

**Files:**
- Modify: `flake.nix` (extend the `perSystem.packages` filter to include the new image)
- Create: `modules/hosts/vasher/_image.nix` (the `nixos-generators` invocation)

Background: the existing `flake.nix` does `pkgs.lib.filterAttrs (...) allPackages` where `allPackages` comes from `./pkgs`. We need to add the LXC image as an x86_64-linux-only package. Simplest path is to extend `./pkgs/default.nix` (or add a module that contributes to `flake.packages`).

Looking at the existing pattern (`flake-parts`'s `perSystem.packages`), the cleanest dendritic addition is a module that registers the image. Let's do that.

- [ ] **Step 1: Create the image-defining module**

```nix
# modules/hosts/vasher/_image.nix
# Exposes `packages.x86_64-linux.vasher-lxc-image` — a Proxmox LXC rootfs tarball.
# Build with: nix build .#vasher-lxc-image
{ inputs, ... }:
{
  perSystem =
    { pkgs, system, ... }:
    {
      packages = pkgs.lib.optionalAttrs (system == "x86_64-linux") {
        vasher-lxc-image = inputs.nixos-generators.nixosGenerate {
          inherit pkgs;
          system = "x86_64-linux";
          format = "proxmox-lxc";
          modules = [ ./_seed.nix ];
        };
      };
    };
}
```

- [ ] **Step 2: Verify the package is discoverable**

Run:
```bash
nix flake show 2>&1 | grep -A1 vasher-lxc-image | head -5
```
Expected: appears under `packages.x86_64-linux.vasher-lxc-image`.

- [ ] **Step 3: Build the image (this will take a while on first run)**

Run:
```bash
nix build .#vasher-lxc-image --print-out-paths 2>&1 | tail -3
```
Expected: prints a store path; under that path there's a `tarball/` directory containing a `.tar.xz`.

- [ ] **Step 4: Inspect the tarball**

Run:
```bash
ls -lh $(nix build .#vasher-lxc-image --no-link --print-out-paths)/tarball/
```
Expected: a single `nixos-system-x86_64-linux.tar.xz` file, size ~300-600MB.

- [ ] **Step 5: Commit**

```bash
git add modules/hosts/vasher/_image.nix
git commit -m "feat(hosts/vasher): expose Proxmox LXC image as flake package"
```

---

## Phase 2 — Proxmox CT provisioning

Goal of this phase: a running NixOS LXC on Proxmox reachable as `vasher.lan` (or your LAN equivalent), with the placeholder `nixosConfigurations.vasher` deployed. No build automation yet.

### Task 2.1: Add the Proxmox CT bootstrap script

**Files:**
- Create: `scripts/bootstrap/proxmox-lxc-create.sh`

- [ ] **Step 1: Create the script**

```bash
#!/usr/bin/env bash
# scripts/bootstrap/proxmox-lxc-create.sh
# Idempotent-ish creation of the vasher NixOS LXC on a Proxmox host.
#
# Run this ON the Proxmox host (not on your dev machine).
# Requires: the vasher-lxc-image tarball already at /var/lib/vz/template/cache/.
#
# Usage:
#   ./proxmox-lxc-create.sh <ctid> <template-filename> [hostname]
# Example:
#   ./proxmox-lxc-create.sh 200 nixos-system-x86_64-linux.tar.xz vasher

set -euo pipefail

CTID="${1:?CTID required (e.g. 200)}"
TEMPLATE="${2:?template filename in /var/lib/vz/template/cache/ required}"
HOSTNAME="${3:-vasher}"
TEMPLATE_PATH="local:vztmpl/${TEMPLATE}"

# Tuning knobs (edit if you want different sizing).
CORES=4
MEMORY=8192        # MB
ROOTFS_GB=100      # CT rootfs size
ROOTFS_STORAGE="local-lvm"
NET_BRIDGE="vmbr0"

if pct status "${CTID}" &>/dev/null; then
  echo "CT ${CTID} already exists — refusing to overwrite. Destroy it first if you really want to recreate." >&2
  exit 1
fi

# Pull the admin SSH key from authorized_keys on the Proxmox host.
SSH_KEYS_FILE="/root/.ssh/authorized_keys"
if [[ ! -f "${SSH_KEYS_FILE}" ]]; then
  echo "No ${SSH_KEYS_FILE} — add your admin SSH key there first." >&2
  exit 1
fi

pct create "${CTID}" "${TEMPLATE_PATH}" \
  --hostname "${HOSTNAME}" \
  --cores "${CORES}" \
  --memory "${MEMORY}" \
  --rootfs "${ROOTFS_STORAGE}:${ROOTFS_GB}" \
  --net0 "name=eth0,bridge=${NET_BRIDGE},ip=dhcp" \
  --features "nesting=1" \
  --unprivileged 1 \
  --ssh-public-keys "${SSH_KEYS_FILE}" \
  --onboot 1 \
  --start 1

echo "CT ${CTID} created and started. Wait ~30s for DHCP, then:"
echo "  ssh root@${HOSTNAME}.lan"
```

- [ ] **Step 2: Make it executable**

Run: `chmod +x scripts/bootstrap/proxmox-lxc-create.sh`

- [ ] **Step 3: shellcheck it**

Run: `nix-shell -p shellcheck --run 'shellcheck scripts/bootstrap/proxmox-lxc-create.sh'`
Expected: no findings, or only style suggestions you accept.

- [ ] **Step 4: Commit**

```bash
git add scripts/bootstrap/proxmox-lxc-create.sh
git commit -m "feat(bootstrap): add Proxmox LXC creation script for vasher"
```

### Task 2.2: Provision vasher on Proxmox (manual, one-time)

**No files** — this is a manual ops procedure. Document the exact commands in the plan so it's reproducible.

- [ ] **Step 1: Build the image locally**

Run:
```bash
nix build .#vasher-lxc-image --print-out-paths
```
Note the output path; the tarball is at `<out>/tarball/nixos-system-x86_64-linux.tar.xz`.

- [ ] **Step 2: Copy the tarball to the Proxmox host**

Run (substitute `proxmox.lan` with your Proxmox hostname):
```bash
scp "$(nix build .#vasher-lxc-image --no-link --print-out-paths)/tarball/"*.tar.xz \
  root@proxmox.lan:/var/lib/vz/template/cache/
```

- [ ] **Step 3: Copy the bootstrap script to the Proxmox host**

Run:
```bash
scp scripts/bootstrap/proxmox-lxc-create.sh root@proxmox.lan:/root/
```

- [ ] **Step 4: Run the bootstrap on the Proxmox host**

```bash
ssh root@proxmox.lan \
  '/root/proxmox-lxc-create.sh 200 nixos-system-x86_64-linux.tar.xz vasher'
```
(Adjust CTID if `200` is taken.)

Expected: prints "CT 200 created and started." and the SSH hint.

- [ ] **Step 5: Verify SSH reachability**

Run:
```bash
ssh root@vasher.lan 'uname -a; cat /etc/os-release | head -3'
```
Expected: prints kernel info and `NAME="NixOS"`.

If DNS doesn't resolve `vasher.lan`, find the CT's IP via `ssh root@proxmox.lan 'pct exec 200 -- ip -4 addr show eth0'` and ssh to the IP directly. (Long-term fix: DHCP reservation + your LAN's DNS.)

- [ ] **Step 6: Copy the locally-generated vasher age private key to vasher**

(From Task 0.3 you have `/tmp/vasher-age.txt`.)

Run:
```bash
ssh root@vasher.lan 'mkdir -p /var/lib/sops-nix'
scp /tmp/vasher-age.txt root@vasher.lan:/var/lib/sops-nix/key.txt
ssh root@vasher.lan 'chmod 0400 /var/lib/sops-nix/key.txt'
```

- [ ] **Step 7: Deploy the real config**

From your dev machine, push the flake to vasher and rebuild:

```bash
nixos-rebuild switch --flake .#vasher --target-host root@vasher.lan
```

Expected: rebuild completes; `vasher` is now running on the real `nixosConfigurations.vasher` instead of the seed. Idempotent: re-run is a no-op if nothing changed.

- [ ] **Step 8: Sanity-check the deployed system**

```bash
ssh root@vasher.lan 'systemctl is-active sshd && id swoleflake && nix --version'
```
Expected: `active`, `swoleflake` uid/gid info, nix version string.

No commit in this task — it's a deploy, not a code change.

---

## Phase 3 — Pre-warm build automation

Goal of this phase: vasher nightly runs `nix flake update` + `nix build jezrien` + push to `cache-bump`, and harmonia is serving its `/nix/store` on LAN.

### Task 3.1: Generate and encrypt secrets

**Files:**
- Modify: `modules/hosts/vasher/secrets.yaml` (replace placeholder with encrypted real content)

- [ ] **Step 1: Generate the deploy SSH key**

Run on your dev machine:
```bash
ssh-keygen -t ed25519 -f /tmp/vasher-deploy -C "vasher@swoleflake-deploy" -N ""
cat /tmp/vasher-deploy.pub
```

- [ ] **Step 2: Add the deploy public key to GitHub**

In GitHub: repo settings → Deploy keys → Add deploy key.
- Title: `vasher cache-bump pusher`
- Key: contents of `/tmp/vasher-deploy.pub`
- **Allow write access:** yes

- [ ] **Step 3: Generate the harmonia signing key**

Run on your dev machine:
```bash
nix-shell -p nix --run \
  'nix-store --generate-binary-cache-key vasher.swoleflake-1 /tmp/vasher-sign.sec /tmp/vasher-sign.pub'
cat /tmp/vasher-sign.pub
```

**Save the contents of `/tmp/vasher-sign.pub` — you'll paste it into Phase 4's cache-substituter module.**

- [ ] **Step 4: Compose secrets.yaml content**

Create a plaintext file `/tmp/vasher-secrets.yaml` with:

```yaml
swoleflake:
  deploy_key: |
$(sed 's/^/    /' /tmp/vasher-deploy)
  harmonia_signing_key: |
    $(cat /tmp/vasher-sign.sec)
```

Or compose manually — the structure is:
```yaml
swoleflake:
  deploy_key: |
    -----BEGIN OPENSSH PRIVATE KEY-----
    <private key content>
    -----END OPENSSH PRIVATE KEY-----
  harmonia_signing_key: |
    vasher.swoleflake-1:<base64-private-key>
```

- [ ] **Step 5: Encrypt with sops**

Run:
```bash
SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt \
  sops --encrypt /tmp/vasher-secrets.yaml > modules/hosts/vasher/secrets.yaml
```

(The placeholder `{}` content is overwritten.)

- [ ] **Step 6: Verify decryption works**

Run:
```bash
SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt \
  sops --decrypt modules/hosts/vasher/secrets.yaml | head -3
```
Expected: prints `swoleflake:` and start of the deploy key.

- [ ] **Step 7: Wipe the plaintext files**

Run: `shred -u /tmp/vasher-secrets.yaml /tmp/vasher-deploy /tmp/vasher-deploy.pub /tmp/vasher-sign.sec`
(Keep `/tmp/vasher-sign.pub` for Phase 4. And keep `/tmp/vasher-age.txt` until it's verified deployed.)

- [ ] **Step 8: Commit**

```bash
git add modules/hosts/vasher/secrets.yaml
git commit -m "feat(hosts/vasher): encrypt deploy and harmonia signing keys"
```

### Task 3.2: Create the harmonia cache module

**Files:**
- Create: `modules/nixos/harmonia-cache.nix`

- [ ] **Step 1: Create the module**

```nix
# modules/nixos/harmonia-cache.nix
# Wraps services.harmonia for the swoleflake build-bot use case.
# Reads its signing key from sops at /run/secrets/swoleflake/harmonia_signing_key.
{ ... }:
{
  flake.modules.nixos.harmonia-cache =
    { config, lib, ... }:
    let
      cfg = config.swoleflake.harmonia;
    in
    {
      options.swoleflake.harmonia = {
        enable = lib.mkEnableOption "harmonia substituter for vasher";
        port = lib.mkOption {
          type = lib.types.port;
          default = 5000;
        };
      };

      config = lib.mkIf cfg.enable {
        sops.secrets."swoleflake/harmonia_signing_key" = {
          owner = "harmonia";
          group = "harmonia";
          mode = "0400";
        };

        services.harmonia = {
          enable = true;
          signKeyPaths = [ config.sops.secrets."swoleflake/harmonia_signing_key".path ];
          settings = {
            bind = "[::]:${toString cfg.port}";
            priority = 30; # lower than cache.nixos.org (40), so jezrien prefers vasher
          };
        };

        networking.firewall.allowedTCPPorts = [ cfg.port ];
      };
    };
}
```

- [ ] **Step 2: Verify it evaluates as a flake module**

Run:
```bash
nix flake check 2>&1 | tail -10
```
Expected: no errors. The module is registered but not yet enabled anywhere.

- [ ] **Step 3: Commit**

```bash
git add modules/nixos/harmonia-cache.nix
git commit -m "feat(nixos): add harmonia-cache module for binary-cache serving"
```

### Task 3.3: Create the swoleflake-prebuild module

**Files:**
- Create: `modules/nixos/swoleflake-prebuild.nix`

This is the biggest single module. It declares the systemd timer + service + build script + gcroot rotation.

- [ ] **Step 1: Create the module**

```nix
# modules/nixos/swoleflake-prebuild.nix
# Nightly timer that:
#   1. pulls origin/master into /var/lib/swoleflake/swoleflake
#   2. runs `nix flake update`
#   3. builds nixosConfigurations.jezrien.config.system.build.toplevel
#   4. on success: registers gcroot, prunes old roots, force-pushes lock to cache-bump
{ ... }:
{
  flake.modules.nixos.swoleflake-prebuild =
    { config, lib, pkgs, ... }:
    let
      cfg = config.swoleflake.prebuild;

      repoDir = "/var/lib/swoleflake/swoleflake";
      gcrootsDir = "/var/lib/swoleflake/gcroots";
      statusFile = "/var/lib/swoleflake/last-build.json";
      keepGcroots = cfg.keepGcroots;

      buildScript = pkgs.writeShellApplication {
        name = "swoleflake-prebuild";
        runtimeInputs = with pkgs; [
          coreutils
          git
          gnused
          jq
          nix
          openssh
        ];
        text = ''
          set -euo pipefail

          REPO_DIR=${lib.escapeShellArg repoDir}
          GCROOTS_DIR=${lib.escapeShellArg gcrootsDir}
          STATUS_FILE=${lib.escapeShellArg statusFile}
          KEEP=${toString keepGcroots}
          DEPLOY_KEY=/run/secrets/swoleflake/deploy_key
          REMOTE=${lib.escapeShellArg cfg.repoUrl}
          TARGET=${lib.escapeShellArg cfg.targetAttr}
          BRANCH=${lib.escapeShellArg cfg.cacheBranch}

          export GIT_SSH_COMMAND="ssh -i $DEPLOY_KEY -o IdentitiesOnly=yes -o StrictHostKeyChecking=accept-new"

          mkdir -p "$GCROOTS_DIR"

          write_status() {
            local status="$1"
            local exit_code="$2"
            jq -n \
              --arg status "$status" \
              --arg started_at "$STARTED_AT" \
              --arg finished_at "$(date -Iseconds)" \
              --arg exit_code "$exit_code" \
              '{status:$status, started_at:$started_at, finished_at:$finished_at, exit_code:($exit_code|tonumber)}' \
              > "$STATUS_FILE"
          }

          STARTED_AT="$(date -Iseconds)"

          # 1. clone or refresh the repo
          if [[ ! -d "$REPO_DIR/.git" ]]; then
            git clone "$REMOTE" "$REPO_DIR"
          fi
          cd "$REPO_DIR"

          if ! git fetch origin; then
            write_status fetch_failed 10
            exit 10
          fi
          git checkout master
          git reset --hard origin/master

          # 2. update lock
          nix flake update

          # 3. build target
          if ! out=$(nix build "$TARGET" --no-link --print-out-paths 2>&1); then
            # Distinguish eval vs realisation failures by message inspection
            if grep -qE 'error: (assertion|undefined variable|.*is not defined)' <<<"$out"; then
              write_status eval_failed 20
              echo "$out" >&2
              exit 20
            fi
            write_status build_failed 30
            echo "$out" >&2
            exit 30
          fi

          # 4. register gcroot
          ROOT_NAME="$(date +%Y%m%dT%H%M%S)-jezrien"
          ln -sfn "$out" "$GCROOTS_DIR/$ROOT_NAME"

          # prune all but the newest $KEEP roots
          mapfile -t old < <(ls -1t "$GCROOTS_DIR" | tail -n "+$((KEEP + 1))")
          for stale in "''${old[@]:-}"; do
            [[ -z "$stale" ]] || rm -f "$GCROOTS_DIR/$stale"
          done

          # 5. nix-collect-garbage (only deletes paths not reachable from gcroots)
          nix-collect-garbage > /dev/null || true

          # 6. commit lock + push
          if git diff --quiet flake.lock; then
            write_status no_lock_change 0
            exit 0
          fi

          git add flake.lock
          git -c user.email=vasher@swoleflake -c user.name=vasher \
            commit -m "chore: nightly flake.lock update ($(date -I))"

          if ! git push --force-with-lease "$REMOTE" "HEAD:$BRANCH"; then
            # retry once after refetch
            git fetch "$REMOTE" "$BRANCH" || true
            if ! git push --force-with-lease "$REMOTE" "HEAD:$BRANCH"; then
              write_status push_failed 40
              exit 40
            fi
          fi

          write_status success 0
        '';
      };
    in
    {
      options.swoleflake.prebuild = {
        enable = lib.mkEnableOption "nightly pre-warm build timer";
        repoUrl = lib.mkOption {
          type = lib.types.str;
          default = "git@github.com:rykugur/dotfiles.git";
        };
        targetAttr = lib.mkOption {
          type = lib.types.str;
          default = ".#nixosConfigurations.jezrien.config.system.build.toplevel";
          description = "Flake attribute path to build.";
        };
        cacheBranch = lib.mkOption {
          type = lib.types.str;
          default = "cache-bump";
        };
        onCalendar = lib.mkOption {
          type = lib.types.str;
          default = "*-*-* 03:00:00";
          description = "systemd OnCalendar spec for the nightly build.";
        };
        keepGcroots = lib.mkOption {
          type = lib.types.int;
          default = 5;
        };
      };

      config = lib.mkIf cfg.enable {
        sops.secrets."swoleflake/deploy_key" = {
          owner = "swoleflake";
          group = "swoleflake";
          mode = "0400";
        };

        # Make /run/secrets/swoleflake/deploy_key readable by the service.
        # (sops-nix puts secrets under /run/secrets/<name> by default.)

        systemd.services.swoleflake-prebuild = {
          description = "Pre-warm swoleflake binary cache (build jezrien toplevel and push lock)";
          after = [ "network-online.target" ];
          wants = [ "network-online.target" ];
          serviceConfig = {
            Type = "oneshot";
            User = "swoleflake";
            Group = "swoleflake";
            WorkingDirectory = "/var/lib/swoleflake";
            ExecStart = "${buildScript}/bin/swoleflake-prebuild";
            # Tight isolation
            ProtectSystem = "strict";
            ReadWritePaths = [ "/var/lib/swoleflake" "/nix/var/nix" ];
            ProtectHome = true;
            NoNewPrivileges = true;
            PrivateTmp = true;
          };
          # Nix needs access to the daemon socket
          environment = {
            HOME = "/var/lib/swoleflake";
            XDG_CACHE_HOME = "/var/lib/swoleflake/.cache";
          };
        };

        systemd.timers.swoleflake-prebuild = {
          description = "Trigger swoleflake-prebuild nightly";
          wantedBy = [ "timers.target" ];
          timerConfig = {
            OnCalendar = cfg.onCalendar;
            Persistent = true; # run on next boot if missed
            RandomizedDelaySec = "10m";
          };
        };

        # GC policy hint — actual rotation lives in the script.
        nix.gc.automatic = false; # script handles it after each successful build
      };
    };
}
```

- [ ] **Step 2: Verify it evaluates**

Run:
```bash
nix flake check 2>&1 | tail -10
```
Expected: no errors. Module is registered, not yet enabled.

- [ ] **Step 3: Verify the build script shellchecks at build time**

Run:
```bash
nix build --no-link --expr '
  let flake = builtins.getFlake (toString ./.);
      pkgs = flake.inputs.nixpkgs.legacyPackages.x86_64-linux;
  in flake.outputs.nixosConfigurations.vasher.pkgs.writeShellApplication {
       name = "noop"; text = "true";
     }' 2>&1 | tail -3
```
This is a smoke check that `writeShellApplication` is available; the real script gets validated when vasher's toplevel builds (Step 5).

- [ ] **Step 4: Enable the modules on vasher's role**

Edit `modules/hosts/vasher/_role.nix`. The `imports = [ inputs.sops-nix.nixosModules.sops ];` line from Task 1.3 already exists — do NOT duplicate it. Add **two new lines** anywhere in the top-level attribute set:

```nix
  # (existing options unchanged)

  # Enable the harmonia substituter and the nightly prebuild timer.
  swoleflake.harmonia.enable = true;
  swoleflake.prebuild.enable = true;
```

The actual module *definitions* are imported via vasher's `default.nix` in the next step (since this is dendritic — the definitions live under `self.modules.nixos.<name>` and need to be passed in `modules = [ ... ]`).

Edit `modules/hosts/vasher/default.nix`:

```nix
{ inputs, self, ... }:
{
  flake.nixosConfigurations.vasher = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = [
      ./_role.nix
      ./_platform-lxc.nix
      self.modules.nixos.harmonia-cache
      self.modules.nixos.swoleflake-prebuild
    ];
    specialArgs = {
      inherit inputs;
      outputs = inputs.self;
      hostname = "vasher";
    };
  };
}
```

- [ ] **Step 5: Verify the closure builds with the new modules**

Run:
```bash
nix build .#nixosConfigurations.vasher.config.system.build.toplevel --no-link --print-out-paths 2>&1 | tail -3
```
Expected: prints a store path. The build script's shellcheck runs here; failure surfaces as an eval/build error.

- [ ] **Step 6: Commit**

```bash
git add modules/nixos/swoleflake-prebuild.nix modules/hosts/vasher/_role.nix modules/hosts/vasher/default.nix
git commit -m "feat(nixos): add swoleflake-prebuild module and wire it onto vasher"
```

### Task 3.4: Add upstream substituters to vasher's role

**Files:**
- Modify: `modules/hosts/vasher/_role.nix`

Background: without explicit `nix.settings.substituters` on vasher's system config, the `swoleflake` build user can't pull from hyprland/nix-gaming/etc., so it'd rebuild them from source on every flake update. Defeats the purpose.

- [ ] **Step 1: Add the substituter block**

In `modules/hosts/vasher/_role.nix`, extend the existing `nix.settings = { ... }` block:

```nix
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" "pipe-operators" ];
    trusted-users = [ "root" "swoleflake" ];
    auto-optimise-store = true;
    substituters = [
      "https://cache.nixos.org"
      "https://hyprland.cachix.org"
      "https://nix-gaming.cachix.org"
      "https://nix-citizen.cachix.org"
      "https://helix.cachix.org"
      "https://pi.cachix.org"
      "https://nyx-cache.chaotic.cx/"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="
      "nix-citizen.cachix.org-1:lPMkWc2X8XD4/7YPEEwXKKBg+SVbYTVrAaLA2wQTKCo="
      "helix.cachix.org-1:ejp9KQpR1FBI2onstMQ34yogDm4OgU2ru6lIwPvuCVs="
      "pi.cachix.org-1:lGeoGJaZ5ZDabuRzkcD5EBTNnDM4HJ1vqeOxlWk1Flk="
      "nyx-cache.chaotic.cx:dJxTrgMC3V3cFfyIiBQDQorG6k1LsqurH/srpMSq7qk="
    ];
  };
```

(The values mirror the `nixConfig` block in `flake.nix`.)

- [ ] **Step 2: Verify the closure still builds**

Run:
```bash
nix build .#nixosConfigurations.vasher.config.system.build.toplevel --no-link --print-out-paths 2>&1 | tail -3
```
Expected: prints a store path.

- [ ] **Step 3: Commit**

```bash
git add modules/hosts/vasher/_role.nix
git commit -m "feat(hosts/vasher): trust upstream cachix substituters"
```

### Task 3.5: Deploy and smoke-test on vasher

**No new files** — this is a deploy + verification task.

- [ ] **Step 1: Deploy**

Run from your dev machine:
```bash
nixos-rebuild switch --flake .#vasher --target-host root@vasher.lan
```
Expected: rebuild completes; new modules are activated.

- [ ] **Step 2: Verify harmonia is up**

```bash
ssh root@vasher.lan 'systemctl is-active harmonia && journalctl -u harmonia --no-pager -n 5'
curl -s http://vasher.lan:5000/nix-cache-info
```
Expected: `active`; cache info output contains `StoreDir: /nix/store`.

- [ ] **Step 3: Verify the prebuild timer is scheduled**

```bash
ssh root@vasher.lan 'systemctl list-timers swoleflake-prebuild.timer --no-pager'
```
Expected: appears in the timer list, NEXT column shows tomorrow 03:00 ± 10m.

- [ ] **Step 4: Trigger the build manually**

```bash
ssh root@vasher.lan 'systemctl start swoleflake-prebuild.service'
ssh root@vasher.lan 'journalctl -u swoleflake-prebuild --no-pager -n 50'
```
Expected: clone happens, flake update runs, build runs (this will take a long time on the first run — anywhere from 20 minutes to several hours depending on how much vasher pulls from upstream caches vs builds locally). On success, the journal shows `success` and `cat /var/lib/swoleflake/last-build.json` shows `"status":"success"`.

- [ ] **Step 5: Verify the push landed**

From your dev machine:
```bash
git fetch origin cache-bump
git log origin/cache-bump --oneline -3
```
Expected: top commit is `chore: nightly flake.lock update (YYYY-MM-DD)` authored by `vasher`.

- [ ] **Step 6: Verify a gcroot was created**

```bash
ssh root@vasher.lan 'ls -lh /var/lib/swoleflake/gcroots/'
```
Expected: one entry like `YYYYMMDDTHHMMSS-jezrien -> /nix/store/...-nixos-system-jezrien-...`.

No commit in this task.

---

## Phase 4 — Jezrien uses vasher

Goal of this phase: jezrien's `nixos-rebuild` consults vasher and hits cache.

### Task 4.1: Create the cache-substituter module

**Files:**
- Create: `modules/nixos/cache-substituter.nix`

- [ ] **Step 1: Create the module**

```nix
# modules/nixos/cache-substituter.nix
# Opt-in client-side trust for the vasher (swoleflake) binary cache.
{ ... }:
{
  flake.modules.nixos.cache-substituter =
    { config, lib, ... }:
    let
      cfg = config.swoleflake.cache;
    in
    {
      options.swoleflake.cache = {
        enable = lib.mkEnableOption "trust the swoleflake (vasher) substituter";
        url = lib.mkOption {
          type = lib.types.str;
          default = "http://vasher.lan:5000/";
        };
        publicKey = lib.mkOption {
          type = lib.types.str;
          # Replace with the actual key generated in Task 3.1 Step 3.
          # Format: vasher.swoleflake-1:<base64-pubkey>
          default = "vasher.swoleflake-1:REPLACE_ME";
        };
      };

      config = lib.mkIf cfg.enable {
        nix.settings = {
          substituters = [ cfg.url ];
          trusted-public-keys = [ cfg.publicKey ];
        };
      };
    };
}
```

**Important:** replace the `default` of `publicKey` with the actual public key string (saved from Task 3.1 Step 3). The format is `vasher.swoleflake-1:<base64>` — match exactly what's in `/tmp/vasher-sign.pub`.

- [ ] **Step 2: Verify it evaluates**

Run: `nix flake check 2>&1 | tail -10`
Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add modules/nixos/cache-substituter.nix
git commit -m "feat(nixos): add cache-substituter module trusting vasher"
```

### Task 4.2: Enable cache-substituter on jezrien

**Files:**
- Modify: `modules/hosts/jezrien/default.nix`

- [ ] **Step 1: Add the module to jezrien's modules list**

Edit `modules/hosts/jezrien/default.nix`. Inside `flake.nixosConfigurations.jezrien = ... .nixosSystem { modules = [ ... ]; }`, after the existing `self.modules.nixos.nix-defaults` and `self.modules.nixos.ssh` lines, add:

```nix
      self.modules.nixos.cache-substituter
```

- [ ] **Step 2: Enable it via a config knob**

Still in `modules/hosts/jezrien/default.nix`, find a top-level place in the modules list (next to other inline config blocks). Add an inline module that flips the flag:

```nix
      { swoleflake.cache.enable = true; }
```

- [ ] **Step 3: Verify jezrien still evaluates**

Run:
```bash
nix eval .#nixosConfigurations.jezrien.config.nix.settings.substituters 2>&1 | tail -5
```
Expected: the list contains `http://vasher.lan:5000/` (alongside existing substituters).

- [ ] **Step 4: Build jezrien's toplevel locally — observe cache hits**

Run (assuming you've already merged `cache-bump` into master locally, or you're testing against the current lock):
```bash
git fetch origin cache-bump
git merge --ff-only origin/cache-bump
sudo nixos-rebuild build --flake .#jezrien 2>&1 | grep -E "copying path|building" | head -20
```
Expected: lots of `copying path '/nix/store/...' from 'http://vasher.lan:5000/'` lines, ~zero `building '/nix/store/...'` lines.

If there are many `building` lines, debug:
- Is vasher's last build's lock in sync with what jezrien is building? `diff <(ssh root@vasher.lan 'cat /var/lib/swoleflake/swoleflake/flake.lock' | jq) <(jq . flake.lock)`
- Is the substituter actually being queried? `curl -v http://vasher.lan:5000/nix-cache-info` from jezrien.
- Is the public key correct? `nix eval .#nixosConfigurations.jezrien.config.nix.settings.trusted-public-keys`

- [ ] **Step 5: Do the real switch**

```bash
sudo nixos-rebuild switch --flake .#jezrien
```

- [ ] **Step 6: Commit**

```bash
git add modules/hosts/jezrien/default.nix
git commit -m "feat(hosts/jezrien): trust vasher's binary cache"
```

---

## Phase 5 — Documentation

### Task 5.1: Add a wiki entry for vasher

**Files:**
- Modify: `wiki/hosts.md` (add a vasher section)
- Modify: `wiki/index.md` (link to vasher if it has a "hosts" list)

- [ ] **Step 1: Read the existing wiki structure**

Read `wiki/index.md` and `wiki/hosts.md` to understand the format.

- [ ] **Step 2: Add a vasher section to `wiki/hosts.md`**

```markdown
## vasher (NixOS LXC, x86_64-linux)

Pre-warming binary cache builder.

- **Role:** Nightly runs `nix flake update`, builds `jezrien.config.system.build.toplevel`, pushes the updated lock to `cache-bump`, serves `/nix/store` via harmonia on port 5000.
- **Host config:** `modules/hosts/vasher/`
- **Key modules:** `modules/nixos/harmonia-cache.nix`, `modules/nixos/swoleflake-prebuild.nix`
- **Substituter URL:** `http://vasher.lan:5000/`
- **Signing key:** `vasher.swoleflake-1:<pubkey>` (also in `modules/nixos/cache-substituter.nix`)
- **Workflow:**
  - LXC: timer fires nightly at 03:00 ± 10m; on success force-pushes `flake.lock` to `cache-bump`.
  - Jezrien: weekly `git fetch && git merge --ff-only origin/cache-bump && sudo nixos-rebuild switch --flake .#jezrien`.
- **Provisioning:** see `docs/superpowers/specs/2026-06-10-vasher-prewarm-cache-design.md` and `scripts/bootstrap/proxmox-lxc-create.sh`.
- **Migration to bare metal:** swap `modules/hosts/vasher/_platform-lxc.nix` for a `_platform-bare.nix`; spec has the steps.
```

- [ ] **Step 3: Commit**

```bash
git add wiki/hosts.md wiki/index.md
git commit -m "docs(wiki): add vasher host entry"
```

---

## Phase 6 — Cleanup of temporary key material

- [ ] **Step 1: Confirm vasher's age key is deployed and usable**

```bash
ssh root@vasher.lan 'ls -l /var/lib/sops-nix/key.txt; cat /var/lib/sops-nix/key.txt | head -1'
```
Expected: shows `# created: ...` (start of an age key file), mode `0400`.

- [ ] **Step 2: Verify a secret actually decrypts on vasher**

```bash
ssh root@vasher.lan 'cat /run/secrets/swoleflake/deploy_key | head -1'
```
Expected: `-----BEGIN OPENSSH PRIVATE KEY-----`.

- [ ] **Step 3: Wipe local temp files**

```bash
shred -u /tmp/vasher-age.txt /tmp/vasher-sign.pub
```

No commit — this is local hygiene.

---

## Verification: end-to-end cache hit on jezrien

After all phases complete, the success criterion is:

1. Wait at least one nightly cycle (or trigger `swoleflake-prebuild.service` manually on vasher).
2. On jezrien: `git fetch origin && git merge --ff-only origin/cache-bump`.
3. `sudo nixos-rebuild switch --flake .#jezrien`.
4. Observe: the output contains many `copying path '...' from 'http://vasher.lan:5000/'` and zero `building '/nix/store/...'` lines for everything in jezrien's closure.

If step 4 is true, the system works.

---

## Out of scope (deferred to future plans)

- Failure notifications via `OnFailure=` unit (ntfy / email).
- TLS termination via Caddy reverse proxy.
- Caching dev shells or custom packages beyond jezrien's closure.
- Cross-architecture (taln) caching.
- Tailscale-based off-LAN access.
- Migration from LXC to bare metal (the design supports it; execute it as a separate plan when needed).
