# Vasher Binary Cache Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Deploy Vasher as an `x86_64-linux` Proxmox LXC that prebuilds Jezrien closures and serves them as a signed LAN binary cache, with explicit `cache-bump` promotion.

**Architecture:** Vasher is a platform-independent NixOS role plus an LXC platform module. Two serialized systemd jobs build the newest `master` revision every 15 minutes and build a nightly `nix flake update` candidate; only the latter publishes `cache-bump`. Harmonia serves retained closures, and Jezrien consumes it solely through `nix.settings.substituters`.

**Tech Stack:** NixOS, flake-parts/import-tree, nixos-generators, sops-nix, systemd, Harmonia, Git, Proxmox LXC.

## Global Constraints

- Vasher MUST be `x86_64-linux`; it needs no GPU and no AMD CPU.
- Vasher MUST NOT be configured as an SSH remote builder; do not add `nix.buildMachines` or `nix.distributedBuilds` anywhere.
- The only cache endpoint is `http://vasher.local.ryk.sh:5000/`, trusted by Vasher's dedicated signing public key.
- `cache-bump` MUST advance only after Vasher builds `nixosConfigurations.jezrien.config.system.build.toplevel` for that exact revision.
- Jobs MUST serialize and coalesce naturally: a busy trigger exits successfully and the next 15-minute master timer processes the newest revision.
- Keep exactly five successful closure GC roots. Failed work MUST NOT advance `cache-bump` or remove good roots.
- Private deploy/signing keys and Vasher's age key MUST be managed by sops; do not commit plaintext secret material.
- Preserve the role/platform split so migration to bare metal changes only the platform module and installation procedure.

---

## File structure

| Path | Responsibility |
|---|---|
| `flake.nix` | Adds `nixos-generators`, following the existing `nixpkgs` input. |
| `modules/hosts/vasher/default.nix` | Registers the `vasher` NixOS configuration and imports its role, LXC platform, and service modules. |
| `modules/hosts/vasher/_role.nix` | Platform-independent identity, sops, build user, upstream caches, and service enablement. |
| `modules/hosts/vasher/_platform-lxc.nix` | Proxmox-LXC-only configuration. |
| `modules/hosts/vasher/_seed.nix` | Minimal SSH/DHCP LXC image configuration. |
| `modules/hosts/vasher/_image.nix` | Exposes `vasher-lxc-image`. |
| `modules/hosts/vasher/secrets.yaml` | Encrypted deploy and Harmonia signing keys. |
| `modules/nixos/vasher-cache.nix` | Harmonia server and Jezrien client options. |
| `modules/nixos/vasher-prebuild.nix` | Serialized Git/worktree/build/publish services and timers. |
| `scripts/bootstrap/proxmox-lxc-create.sh` | Reproducible Proxmox CT creation. |
| `modules/hosts/jezrien/default.nix` | Imports the Vasher client module. |
| `modules/hosts/jezrien/_configuration.nix` | Enables the cache client with the generated public key. |
| `wiki/hosts.md` | Documents Vasher and the operator promotion workflow. |

---

### Task 1: Add the generator input and platform-independent Vasher host

**Files:**
- Modify: `flake.nix:16-28`
- Create: `modules/hosts/vasher/_role.nix`
- Create: `modules/hosts/vasher/_platform-lxc.nix`
- Create: `modules/hosts/vasher/default.nix`

**Interfaces:**
- Produces: `nixosConfigurations.vasher` for later image and deployment tasks.
- Consumes: `inputs.sops-nix.nixosModules.sops`, `self.modules.nixos.nix-defaults`, and the service modules introduced in Tasks 4–5.

- [ ] **Step 1: Add the generator input below `import-tree` in `flake.nix`**

```nix
nixos-generators = {
  url = "github:nix-community/nixos-generators";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

- [ ] **Step 2: Create `modules/hosts/vasher/_platform-lxc.nix`**

```nix
{ modulesPath, lib, ... }:
{
  imports = [ "${modulesPath}/virtualisation/proxmox-lxc.nix" ];

  boot.isContainer = true;
  boot.loader.grub.enable = lib.mkForce false;
  boot.loader.systemd-boot.enable = lib.mkForce false;
  fileSystems = lib.mkForce { };

  proxmoxLXC.manageNetwork = false;
  proxmoxLXC.privileged = false;
}
```

- [ ] **Step 3: Create `modules/hosts/vasher/_role.nix`**

```nix
{ inputs, pkgs, ... }:
{
  imports = [ inputs.sops-nix.nixosModules.sops ];

  networking.hostName = "vasher";
  time.timeZone = "America/Chicago";
  i18n.defaultLocale = "en_US.UTF-8";

  nix = {
    settings = {
      experimental-features = "nix-command flakes pipe-operators";
      trusted-users = [ "root" "vasher" ];
      auto-optimise-store = true;
      substituters = [
        "https://cache.nixos.org"
        "https://hyprland.cachix.org"
        "https://nix-gaming.cachix.org"
        "https://nix-citizen.cachix.org"
        "https://helix.cachix.org"
        "https://pi.cachix.org"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16XjVwE2G2vQhmo="
        "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
        "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="
        "nix-citizen.cachix.org-1:lPMkWc2X8XD4/7YPEEwXKKBg+SVbYTVrAaLA2wQTKCo="
        "helix.cachix.org-1:ejp9KQpR1FBI2onstMQ34yogDm4OgU2ru6lIwPvuCVs="
        "pi.cachix.org-1:lGeoGJaZ5ZDabuRzkcD5EBTNnDM4HJ1vqeOxlWk1Flk="
      ];
    };
  };

  users.groups.vasher = { };
  users.users.vasher = {
    isSystemUser = true;
    group = "vasher";
    home = "/var/lib/vasher";
    createHome = true;
    shell = pkgs.bashInteractive;
  };

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

  sops = {
    defaultSopsFile = ./secrets.yaml;
    age.keyFile = "/var/lib/sops-nix/key.txt";
  };

  networking.firewall.enable = true;
  environment.systemPackages = with pkgs; [ git jq ];
  system.stateVersion = "24.11";
}
```

- [ ] **Step 4: Register the host**

Create `modules/hosts/vasher/default.nix`:

```nix
{ inputs, self, ... }:
{
  flake.nixosConfigurations.vasher = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = [
      self.modules.nixos.nix-defaults
      ./_role.nix
      ./_platform-lxc.nix
    ];
    specialArgs = { inherit inputs; };
  };
}
```

- [ ] **Step 5: Verify host evaluation and commit**

Run:
```bash
nix eval .#nixosConfigurations.vasher.config.networking.hostName
```
Expected: `"vasher"`.

```bash
git add flake.nix modules/hosts/vasher
git commit -m "feat(hosts): add Vasher LXC host role"
```

### Task 2: Add the minimal LXC image and reproducible Proxmox bootstrap

**Files:**
- Create: `modules/hosts/vasher/_seed.nix`
- Create: `modules/hosts/vasher/_image.nix`
- Create: `scripts/bootstrap/proxmox-lxc-create.sh`

**Interfaces:**
- Produces: `packages.x86_64-linux.vasher-lxc-image` and a script that creates CT 200 with the resource constraints in the approved design.

- [ ] **Step 1: Create `modules/hosts/vasher/_seed.nix`**

```nix
{ modulesPath, ... }:
{
  imports = [ "${modulesPath}/virtualisation/proxmox-lxc.nix" ];
  networking.hostName = "vasher";
  networking.useDHCP = true;
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    trusted-users = [ "root" ];
  };
  services.openssh = {
    enable = true;
    settings = { PermitRootLogin = "prohibit-password"; PasswordAuthentication = false; };
  };
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAgLk3xlBbjNte2VW4ZE6ewngB07bZ1MdkOBnJFFnzQV"
  ];
  system.stateVersion = "24.11";
}
```

- [ ] **Step 2: Create `modules/hosts/vasher/_image.nix`**

```nix
{ inputs, ... }:
{
  perSystem = { pkgs, system, ... }: {
    packages = pkgs.lib.optionalAttrs (system == "x86_64-linux") {
      vasher-lxc-image = inputs.nixos-generators.nixosGenerate {
        inherit pkgs;
        format = "proxmox-lxc";
        modules = [ ./_seed.nix ];
      };
    };
  };
}
```

- [ ] **Step 3: Create `scripts/bootstrap/proxmox-lxc-create.sh`**

```bash
#!/usr/bin/env bash
set -euo pipefail

image=${1:?usage: $0 /var/lib/vz/template/cache/nixos-system-x86_64-linux.tar.xz}
pct create 200 "local:vztmpl/$(basename "$image")" \
  --hostname vasher --cores 4 --memory 8192 --rootfs local-lvm:100 \
  --net0 name=eth0,bridge=vmbr0,ip=dhcp --features nesting=1 \
  --unprivileged 1 --ssh-public-keys ~/.ssh/authorized_keys
pct start 200
```

- [ ] **Step 4: Verify image output and commit**

Run:
```bash
nix build .#vasher-lxc-image --no-link --print-out-paths
```
Expected: one store path containing `tarball/` and a `.tar.xz` image.

```bash
git add modules/hosts/vasher/_seed.nix modules/hosts/vasher/_image.nix scripts/bootstrap/proxmox-lxc-create.sh
git commit -m "feat(vasher): add Proxmox LXC image and bootstrap"
```

### Task 3: Establish Vasher's encrypted identity and cache keys

**Files:**
- Modify: `.sops.yaml`
- Create: `modules/hosts/vasher/secrets.yaml`
- Create: `modules/hosts/vasher/cache-signing-key.pub`

**Interfaces:**
- Produces: `swoleflake/deploy_key` and `swoleflake/harmonia_signing_key` sops secret paths plus `cache-signing-key.pub`, the versioned public key imported by both cache roles.

- [ ] **Step 1: Create and retain the dedicated age bootstrap identity**

Run locally without displaying its private output:

```bash
umask 077
age-keygen -o /tmp/vasher-sops-age.txt
age-keygen -y /tmp/vasher-sops-age.txt
```

Store `/tmp/vasher-sops-age.txt` in 1Password. Add the resulting public `age1...` recipient to `.sops.yaml`, with the existing operator recipient, for `modules/hosts/vasher/secrets.yaml`. The private age identity is copied later to `/var/lib/sops-nix/key.txt` after the seed LXC boots; it is never committed.

- [ ] **Step 2: Create and centrally retain host, deploy, and cache identities**

Keep the 1Password-managed SSH host private key under the YAML key `ssh_host_ed25519_key`. Create a GitHub deploy key restricted to `cache-bump` and a Harmonia keypair named `vasher.swoleflake-1`; install the Harmonia public half at `modules/hosts/vasher/cache-signing-key.pub`.

- [ ] **Step 3: Encrypt the final secret document**

Using `sops`, encrypt `modules/hosts/vasher/secrets.yaml` to the operator and Vasher age recipients. It must contain only these key paths:

```text
ssh_host_ed25519_key
swoleflake/deploy_key
swoleflake/harmonia_signing_key
```

Do not read, display, or commit plaintext private key material.


- [ ] **Step 4: Verify encryption and commit only encrypted configuration**

Run:
```bash
sops --decrypt modules/hosts/vasher/secrets.yaml >/dev/null
```

```bash
git add .sops.yaml modules/hosts/vasher/secrets.yaml modules/hosts/vasher/cache-signing-key.pub
git commit -m "feat(vasher): add encrypted cache identities"
```

### Task 4: Implement the signed Harmonia server and client cache module

**Files:**
- Create: `modules/nixos/vasher-cache.nix`
- Modify: `modules/hosts/vasher/default.nix`
- Modify: `modules/hosts/vasher/_role.nix`

**Interfaces:**
- Produces: `ryk.vasherCache.enable`, `ryk.vasherCache.url`, and a public key loaded from `modules/hosts/vasher/cache-signing-key.pub`; enabling the server also materializes the 1Password-managed SSH host key and configures Harmonia.

- [ ] **Step 1: Create `modules/nixos/vasher-cache.nix`**

```nix
{ ... }:
let
  publicKey = builtins.readFile ../hosts/vasher/cache-signing-key.pub;
in
{
  flake.modules.nixos.vasher-cache = { config, lib, ... }:
    let cfg = config.ryk.vasherCache;
    in {
      options.ryk.vasherCache = {
        enable = lib.mkEnableOption "the Vasher LAN binary cache";
        url = lib.mkOption { type = lib.types.str; default = "http://vasher.local.ryk.sh:5000/"; };
        serve = lib.mkOption { type = lib.types.bool; default = false; };
      };

      config = lib.mkIf cfg.enable (lib.mkMerge [
        {
          nix.settings = {
            substituters = [ cfg.url ];
            trusted-public-keys = [ publicKey ];
          };
        }
        (lib.mkIf cfg.serve {
          sops.secrets.vasher_ssh_host_ed25519_key = {
            key = "ssh_host_ed25519_key";
            owner = "root";
            group = "root";
            mode = "0600";
          };
          sops.secrets.vasher_harmonia_signing_key = {
            key = "swoleflake/harmonia_signing_key";
            owner = "harmonia";
            group = "harmonia";
            mode = "0400";
          };
          services.openssh.hostKeys = [
            {
              path = config.sops.secrets.vasher_ssh_host_ed25519_key.path;
              type = "ed25519";
            }
          ];
          services.harmonia = {
            enable = true;
            signKeyPaths = [ config.sops.secrets.vasher_harmonia_signing_key.path ];
            settings = {
              bind = "[::]:5000";
              priority = 30;
            };
          };
          networking.firewall.interfaces.eth0.allowedTCPPorts = [ 5000 ];
        })
      ]);
    };
}
```

- [ ] **Step 2: Enable and import the server module**

Append this to `modules/hosts/vasher/_role.nix`:

```nix
  ryk.vasherCache = {
    enable = true;
    serve = true;
  };
```

Add `self.modules.nixos.vasher-cache` after `./_platform-lxc.nix` in `modules/hosts/vasher/default.nix`.

- [ ] **Step 3: Verify the Vasher closure and commit**

Run:
```bash
nix build .#nixosConfigurations.vasher.config.system.build.toplevel --no-link --print-out-paths
```
Expected: a Vasher system store path; Nix accepts the Harmonia secret ownership and service configuration.

git add modules/nixos/vasher-cache.nix modules/hosts/vasher/default.nix modules/hosts/vasher/_role.nix
git commit -m "feat(vasher): serve signed Harmonia cache"
```

### Task 5: Implement serialized master prebuilds and nightly candidate publication

**Files:**
- Create: `modules/nixos/vasher-prebuild.nix`
- Modify: `modules/hosts/vasher/_role.nix`

**Interfaces:**
- Produces: `vasher-prebuild-master.service`, `vasher-prebuild-candidate.service`, their timers, `/var/lib/vasher/gcroots`, and `/var/lib/vasher/last-build.json`.

- [ ] **Step 1: Create `modules/nixos/vasher-prebuild.nix` with the shared script**

Define `flake.modules.nixos.vasher-prebuild` with options `enable`, `repoUrl` defaulting to `git@github.com:rykugur/dotfiles.git`, `targetAttr` defaulting to `nixosConfigurations.jezrien.config.system.build.toplevel`, `cacheBranch` defaulting to `cache-bump`, and `keepRoots` defaulting to `5`.

Its `pkgs.writeShellApplication` MUST use `bash`, `coreutils`, `git`, `jq`, `nix`, `openssh`, and `util-linux`, and implement this exact control flow:

```bash
exec 9>/var/lib/vasher/prebuild.lock
flock -n 9 || exit 0

repo=/var/lib/vasher/repo
roots=/var/lib/vasher/gcroots
mode=$1
mkdir -p "$roots"
[[ -d "$repo/.git" ]] || git clone "$REPO_URL" "$repo"
git -C "$repo" fetch origin master
worktree=/var/lib/vasher/worktrees/"$mode"
if [[ ! -d "$worktree/.git" ]]; then
  mkdir -p "$(dirname "$worktree")"
  git -C "$repo" worktree add --detach "$worktree" origin/master
fi
git -C "$worktree" fetch origin master
git -C "$worktree" reset --hard origin/master

if [[ $mode == candidate ]]; then
  nix flake update --flake "$worktree"
fi

out=$(nix build "$worktree#$TARGET_ATTR" --no-link --print-out-paths)
ln -sfn "$out" "$roots/$(date -u +%Y%m%dT%H%M%SZ)-$mode"
mapfile -t stale < <(ls -1t "$roots" | tail -n +$((KEEP_ROOTS + 1)))
for root in "${stale[@]:-}"; do rm -f "$roots/$root"; done
nix-collect-garbage

if [[ $mode == candidate ]]; then
  git -C "$worktree" add flake.lock
  if ! git -C "$worktree" diff --cached --quiet; then
    git -C "$worktree" -c user.name=vasher -c user.email=vasher@localhost \
      commit -m "chore: nightly flake.lock update ($(date -I))"
  fi
  git -C "$worktree" push --force-with-lease origin "HEAD:$CACHE_BRANCH" || {
    git -C "$worktree" fetch origin "$CACHE_BRANCH:refs/remotes/origin/$CACHE_BRANCH"
    git -C "$worktree" push --force-with-lease origin "HEAD:$CACHE_BRANCH"
  }
fi
jq -n --arg mode "$mode" --arg out "$out" --arg revision "$(git -C "$worktree" rev-parse HEAD)" \
  '{status:"success",mode:$mode,output:$out,revision:$revision}' > /var/lib/vasher/last-build.json
```

Wrap failure paths with `trap` so `last-build.json` records `status: "failed"`, the selected `mode`, and the non-zero exit code before returning that code.

- [ ] **Step 2: Declare service isolation and timers**

Enable the deploy-key sops secret with owner/group `vasher`, mode `0400`. Create both oneshot services with `User = "vasher"`, `Group = "vasher"`, `WorkingDirectory = "/var/lib/vasher"`, `HOME = "/var/lib/vasher"`, `ProtectHome = true`, `PrivateTmp = true`, `NoNewPrivileges = true`, and writable paths `/var/lib/vasher` and `/nix/var/nix`.

Set `GIT_SSH_COMMAND` to:

```text
ssh -i /run/secrets/swoleflake/deploy_key -o IdentitiesOnly=yes -o StrictHostKeyChecking=accept-new
```

Create:

```nix
systemd.timers.vasher-prebuild-master.timerConfig = {
  OnBootSec = "5m";
  OnUnitInactiveSec = "15m";
  Persistent = true;
};
systemd.timers.vasher-prebuild-candidate.timerConfig = {
  OnCalendar = "*-*-* 03:00:00";
  Persistent = true;
  RandomizedDelaySec = "10m";
};
```

- [ ] **Step 3: Enable and import it from the Vasher host**

Add to `modules/hosts/vasher/_role.nix`:

```nix
  ryk.vasherPrebuild.enable = true;
```

Add `self.modules.nixos.vasher-prebuild` after `self.modules.nixos.vasher-cache` in `modules/hosts/vasher/default.nix`.

Run:
```bash
nix build .#nixosConfigurations.vasher.config.system.build.toplevel --no-link --print-out-paths
```
Expected: successful closure build; `writeShellApplication` shellchecks the embedded script.

- [ ] **Step 4: Commit**

```bash
git add modules/nixos/vasher-prebuild.nix modules/hosts/vasher/default.nix modules/hosts/vasher/_role.nix
git commit -m "feat(vasher): prebuild master and nightly candidates"
```

### Task 6: Configure Jezrien strictly as a cache consumer

**Files:**
- Modify: `modules/hosts/jezrien/default.nix:19-55`
- Modify: `modules/hosts/jezrien/_configuration.nix:25-35`

**Interfaces:**
- Consumes: `self.modules.nixos.vasher-cache`, which loads the Task 3 public key.
- Produces: Jezrien cache-first substitution with no remote-builder settings.

- [ ] **Step 1: Import the client module in Jezrien's NixOS module list**

Add this after `self.modules.nixos.nix-defaults` in `modules/hosts/jezrien/default.nix`:

```nix
self.modules.nixos.vasher-cache
```

- [ ] **Step 2: Enable the client in `_configuration.nix`**

Add this top-level attribute:

```nix
ryk.vasherCache.enable = true;
```

Do not add `buildMachines`, `distributedBuilds`, SSH keys, or any remote-builder option.

- [ ] **Step 3: Verify the configuration contract and commit**

Run:
```bash
nix eval .#nixosConfigurations.jezrien.config.nix.settings.substituters --json
nix eval .#nixosConfigurations.jezrien.config.nix.buildMachines --json
```
Expected: the first output contains `http://vasher.local.ryk.sh:5000/`; the second is `[]`.

```bash
git add modules/hosts/jezrien/default.nix modules/hosts/jezrien/_configuration.nix
git commit -m "feat(jezrien): consume Vasher binary cache"
```

### Task 7: Provision, smoke-test, and document operations

**Files:**
- Modify: `wiki/hosts.md:10-60`

**Interfaces:**
- Consumes: completed LXC image, encrypted secrets, and final public key.
- Produces: a deployed cache endpoint and operator documentation.

- [ ] **Step 1: Provision the LXC and deploy the real configuration**

Run:
```bash
nix build .#vasher-lxc-image
scp result/tarball/*.tar.xz proxmox:/var/lib/vz/template/cache/
ssh proxmox 'bash -s -- /var/lib/vz/template/cache/nixos-system-x86_64-linux.tar.xz' \
  < scripts/bootstrap/proxmox-lxc-create.sh
scp -r /tmp/vasher-sops-key vasher.local.ryk.sh:/var/lib/sops-nix/
ssh root@vasher.local.ryk.sh 'chmod 700 /var/lib/sops-nix && chmod 400 /var/lib/sops-nix/key.txt && nixos-rebuild switch --flake github:rykugur/dotfiles#vasher'
```

- [ ] **Step 2: Verify scheduler, server, and successful candidate behavior**

Run:
```bash
ssh root@vasher.local.ryk.sh 'systemctl list-timers vasher-prebuild-master.timer vasher-prebuild-candidate.timer --no-pager'
ssh root@vasher.local.ryk.sh 'systemctl start vasher-prebuild-candidate.service'
curl --fail http://vasher.local.ryk.sh:5000/nix-cache-info
ssh root@vasher.local.ryk.sh 'cat /var/lib/vasher/last-build.json && ls -1 /var/lib/vasher/gcroots'
```

Expected: both timers are scheduled; the candidate service records success and publishes the built revision; `nix-cache-info` returns HTTP 200; at most five roots exist after six successful runs.

- [ ] **Step 3: Verify the end-to-end Jezrien consumer path**

On Jezrien:

```bash
git fetch origin
git merge --ff-only origin/cache-bump
git push origin master
sudo nixos-rebuild switch --flake .#jezrien 2>&1 | tee /tmp/vasher-switch.log
grep -F "http://vasher.local.ryk.sh:5000" /tmp/vasher-switch.log
```

Expected: the switch downloads matching paths from Vasher; no local `building '/nix/store/…'` line appears for paths already retained by Vasher.

- [ ] **Step 4: Add the Vasher section to `wiki/hosts.md` and commit**

Insert before `## nixy (test container)`:

```markdown
## vasher (LAN binary cache)

- **Platform**: `x86_64-linux`, NixOS, initially a Proxmox LXC
- **Purpose**: prebuild Jezrien's current `master` closure and a nightly updated-lock candidate; serve retained signed paths over `http://vasher.local.ryk.sh:5000/`
- **Not a remote builder**: Jezrien only substitutes cache paths; it never delegates builds over SSH.
- **Promotion**: `git fetch origin && git merge --ff-only origin/cache-bump && git push origin master && sudo nixos-rebuild switch --flake .#jezrien`
- **Retention**: five successful closures under `/var/lib/vasher/gcroots`
- **Migration**: retain the role module and replace the LXC platform module with bare-metal hardware, filesystem, bootloader, and networking configuration.
```

```bash
git add wiki/hosts.md
git commit -m "docs: document Vasher cache workflow"
```

## Plan self-review

- Spec coverage: Tasks 1–2 implement the LXC host/image and migration boundary; Task 3 implements separate encrypted identities; Task 4 implements signed LAN cache serving; Task 5 implements current-master and nightly-candidate prebuild workflows, locking, retention, failure recording, and `cache-bump`; Task 6 prohibits remote-builder wiring while configuring Jezrien's cache client; Task 7 verifies real deployment and documents promotion.
- Placeholder scan: all implementation paths, commands, service names, timer schedules, cache URL, host architecture, retention count, and flake target are explicit. The only runtime-injected values are generated cryptographic key material, which must not be committed in plaintext.
- Type consistency: `ryk.vasherCache` is defined in Task 4 and consumed in Tasks 4 and 6. `ryk.vasherPrebuild` is produced in Task 5 and enabled from Task 5's role edit. Service/timer names are consistently `vasher-prebuild-master` and `vasher-prebuild-candidate`.
