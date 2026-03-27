# Hosts Consolidation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Consolidate `hosts/` into `modules/hosts/` so each host lives in a single directory with all config.

**Architecture:** Convert `modules/hosts/<name>.nix` to `modules/hosts/<name>/default.nix`, move host files from `hosts/<name>/` with `_` prefix (for import-tree exclusion), absorb home-manager config inline into `default.nix`, update sops paths.

**Tech Stack:** Nix, home-manager, flake-parts, import-tree, sops-nix

**Spec:** `docs/superpowers/specs/2026-03-26-hosts-consolidation-design.md`

---

### File Map

| Action | File | Responsibility |
|--------|------|----------------|
| Create | `modules/hosts/jezrien/default.nix` | Dendritic wiring + all HM config |
| Move+Rename | `hosts/jezrien/configuration.nix` → `modules/hosts/jezrien/_configuration.nix` | Pure NixOS system config |
| Move+Rename | `hosts/jezrien/hardware-configuration.nix` → `modules/hosts/jezrien/_hardware-configuration.nix` | Generated hardware config |
| Move+Rename | `hosts/jezrien/niri-config.nix` → `modules/hosts/jezrien/_niri-config.nix` | Niri WM config |
| Move+Rename | `hosts/jezrien/hyprland-config.nix` → `modules/hosts/jezrien/_hyprland-config.nix` | Hyprland WM config |
| Move | `hosts/jezrien/secrets.yaml` → `modules/hosts/jezrien/secrets.yaml` | Sops secrets |
| Create | `modules/hosts/taln/default.nix` | Dendritic wiring + all HM config |
| Move+Rename | `hosts/taln/configuration.nix` → `modules/hosts/taln/_configuration.nix` | Pure Darwin system config |
| Move | `hosts/taln/secrets.yaml` → `modules/hosts/taln/secrets.yaml` | Sops secrets |
| Modify | `home/default.nix` | Update sops defaultSopsFile path |
| Modify | `modules/misc/ssh.nix` | Update sops sopsFile path |
| Delete | `hosts/` (entire directory) | No longer needed |
| Delete | `modules/hosts/jezrien.nix` | Replaced by directory |
| Delete | `modules/hosts/taln.nix` | Replaced by directory |

---

### Task 1: Consolidate jezrien into `modules/hosts/jezrien/`

Move files, create `default.nix`, remove old module — all atomically so the build is never broken.

**Files:**
- Create: `modules/hosts/jezrien/default.nix`
- Move: `hosts/jezrien/configuration.nix` → `modules/hosts/jezrien/_configuration.nix`
- Move: `hosts/jezrien/hardware-configuration.nix` → `modules/hosts/jezrien/_hardware-configuration.nix`
- Move: `hosts/jezrien/niri-config.nix` → `modules/hosts/jezrien/_niri-config.nix`
- Move: `hosts/jezrien/hyprland-config.nix` → `modules/hosts/jezrien/_hyprland-config.nix`
- Move: `hosts/jezrien/secrets.yaml` → `modules/hosts/jezrien/secrets.yaml`
- Delete: `modules/hosts/jezrien.nix`

- [ ] **Step 1: Create directory and move files**

```bash
mkdir -p modules/hosts/jezrien
git mv hosts/jezrien/configuration.nix modules/hosts/jezrien/_configuration.nix
git mv hosts/jezrien/hardware-configuration.nix modules/hosts/jezrien/_hardware-configuration.nix
git mv hosts/jezrien/niri-config.nix modules/hosts/jezrien/_niri-config.nix
git mv hosts/jezrien/hyprland-config.nix modules/hosts/jezrien/_hyprland-config.nix
git mv hosts/jezrien/secrets.yaml modules/hosts/jezrien/secrets.yaml
```

- [ ] **Step 2: Update `_configuration.nix` import paths and remove HM setup**

In `modules/hosts/jezrien/_configuration.nix`:

Update the imports list to:

```nix
  imports = [
    ./_hardware-configuration.nix

    # ./_hyprland-config.nix
    ./_niri-config.nix
  ]
  ++ (with inputs.nixos-hardware.nixosModules; [
    common-pc
    common-pc-ssd
    common-cpu-amd
    common-gpu-amd
  ]);
```

This removes `inputs.home-manager.nixosModules.home-manager` (line 13) and updates the file references to use underscore prefixes.

Delete the entire `home-manager` block at the end of the file (lines 189-202):

```nix
  home-manager = {
    extraSpecialArgs = {
      inherit
        inputs
        outputs
        hostname
        username
        ;
    };
    users = {
      ${username} = import ./home.nix;
    };
    backupFileExtension = "bak";
  };
```

- [ ] **Step 3: Create `modules/hosts/jezrien/default.nix`**

```nix
# Jezrien — NixOS desktop (x86_64-linux)
{
  config,
  inputs,
  self,
  ...
}:
let
  # TODO: this can be removed once all modules are migrated
  username = "dusty";
  hmModules = config.flake.modules.homeManager;
in
{
  flake.nixosConfigurations.jezrien = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      ../../../legacy-modules/nixos
      ../../../legacy-modules

      self.modules.nixos.nix-defaults
      self.modules.nixos.ssh

      ./_configuration.nix

      inputs.home-manager.nixosModules.home-manager
      inputs.stylix.nixosModules.stylix

      self.modules.nixos.meta
      self.modules.nixos.fonts
      self.modules.nixos.stylix

      self.modules.nixos.pipewire
      self.modules.nixos.starcitizen

      # home-manager config
      {
        home-manager = {
          extraSpecialArgs = {
            inherit
              inputs
              username
              ;
            outputs = inputs.self;
            hostname = "jezrien";
          };
          backupFileExtension = "bak";

          users.${username} = { pkgs, ... }: {
            imports =
              [ ../../../home ]
              ++ (with hmModules; [
                # groups
                developer
                gaming
                _3dp

                # individual modules
                btop
                ccstatusline
                claude-code
                eve-online
                homelab
                keebs
                nushell
                opencode
                starsector
                swappy
                television
                wezterm
                zen-browser
              ]);

            nixpkgs.config.permittedInsecurePackages = [
              "electron-25.9.0"
              "nexusmods-app-unfree-0.21.1"
            ];

            sops.secrets = {
              homelab_ssh_private_key = {
                sopsFile = ./secrets.yaml;
              };
            };

            home.packages = with pkgs; [
              # nix
              nix-prefetch-scripts
              nixd
              nix-index

              # fonts
              font-awesome

              # desktop
              arandr
              cliphist
              xrandr
              xbacklight

              nwg-look
              catppuccin-gtk
              catppuccin-cursors
              catppuccin-papirus-folders

              affine
              baobab
              bottom
              fastfetch
              fd
              file
              file-roller
              minder
              mousai
              nemo
              nitch
              obsidian
              pavucontrol
              playerctl
              rcon-cli
              seahorse
              spotify
              sshfs
              tigervnc
              tldr
              vlc
              xdg-utils
              zenity

              yt-dlg
              yt-dlp

              amdgpu_top
              radeontop

              feh
              ristretto

              libtool

              telegram-desktop

              google-chrome

              beyond-all-reason
              kalker
            ];

            programs.ghostty.settings.window-decoration = "none";
            programs.home-manager.enable = true;

            systemd.user.startServices = "sd-switch";

            home.stateVersion = "23.11";
          };
        };
      }
    ];
    specialArgs = {
      inherit
        inputs
        # TODO: this can be removed once all modules are migrated
        username
        ;
      outputs = inputs.self;
      hostname = "jezrien";
    };
  };
}
```

Key path differences from old `modules/hosts/jezrien.nix` (now one directory level deeper):
- `../../legacy-modules` → `../../../legacy-modules` (3 levels to repo root)
- `../../hosts/jezrien` → `./_configuration.nix` (sibling file)
- `../../../home` for HM base import (3 levels to repo root)

- [ ] **Step 4: Delete old `modules/hosts/jezrien.nix`**

```bash
rm modules/hosts/jezrien.nix
```

- [ ] **Step 5: Commit**

```bash
git add modules/hosts/jezrien/default.nix
git add -A modules/hosts/jezrien.nix modules/hosts/jezrien/_configuration.nix modules/hosts/jezrien/_hardware-configuration.nix modules/hosts/jezrien/_niri-config.nix modules/hosts/jezrien/_hyprland-config.nix modules/hosts/jezrien/secrets.yaml
git commit -m "consolidate jezrien into modules/hosts/jezrien/ with inline home-manager config"
```

---

### Task 2: Consolidate taln into `modules/hosts/taln/`

Same pattern as jezrien — move files, create `default.nix`, remove old module atomically.

**Files:**
- Create: `modules/hosts/taln/default.nix`
- Move: `hosts/taln/configuration.nix` → `modules/hosts/taln/_configuration.nix`
- Move: `hosts/taln/secrets.yaml` → `modules/hosts/taln/secrets.yaml`
- Delete: `modules/hosts/taln.nix`

- [ ] **Step 1: Create directory and move files**

```bash
mkdir -p modules/hosts/taln
git mv hosts/taln/configuration.nix modules/hosts/taln/_configuration.nix
git mv hosts/taln/secrets.yaml modules/hosts/taln/secrets.yaml
```

- [ ] **Step 2: Remove HM setup from `_configuration.nix`**

In `modules/hosts/taln/_configuration.nix`:

Remove the `imports` line (line 3): `imports = [ inputs.home-manager.darwinModules.home-manager ];`

Remove the entire `home-manager` block (lines 69-75):

```nix
  ### home-manager config

  home-manager = {
    extraSpecialArgs = { inherit inputs outputs hostname username; };
    users = { ${username} = import ./home.nix; };
    backupFileExtension = "bak";
  };
```

The file should start with:

```nix
{ inputs, outputs, hostname, username, ... }: {
  ### system config

  nixpkgs = {
```

- [ ] **Step 3: Create `modules/hosts/taln/default.nix`**

```nix
# Taln — macOS (aarch64-darwin)
{
  config,
  inputs,
  self,
  ...
}:
let
  # TODO: this can be removed once all modules are migrated
  username = "dusty";
  hmModules = config.flake.modules.homeManager;
in
{
  flake.darwinConfigurations.taln = inputs.nix-darwin.lib.darwinSystem {
    modules = [
      ./_configuration.nix

      inputs.home-manager.darwinModules.home-manager
      inputs.stylix.darwinModules.stylix

      self.modules.darwin.fonts
      self.modules.darwin.stylix
      self.modules.darwin.aerospace

      # home-manager config
      {
        home-manager = {
          extraSpecialArgs = {
            inherit inputs;
            outputs = inputs.self;
            hostname = "taln";
            username = "dusty";
          };
          backupFileExtension = "bak";

          users.${username} = { pkgs, ... }: {
            imports =
              [ ../../../home ]
              ++ (with hmModules; [
                # group
                developer

                # individual modules (not in developer group)
                ccstatusline
                claude-code
                homelab
                nushell
                opencode
                ssh
                television
              ]);

            home.packages = with pkgs; [
              nh
              nix-prefetch-scripts
              _1password-cli
              fd
              tldr
            ];

            programs.home-manager.enable = true;

            home.stateVersion = "23.11";
          };
        };
      }
    ];
    specialArgs = {
      inherit inputs;
      outputs = inputs.self;
      hostname = "taln";
      username = "dusty";
    };
  };
}
```

- [ ] **Step 4: Delete old `modules/hosts/taln.nix`**

```bash
rm modules/hosts/taln.nix
```

- [ ] **Step 5: Commit**

```bash
git add modules/hosts/taln/default.nix
git add -A modules/hosts/taln.nix modules/hosts/taln/_configuration.nix modules/hosts/taln/secrets.yaml
git commit -m "consolidate taln into modules/hosts/taln/ with inline home-manager config"
```

---

### Task 3: Update sops paths

Three files reference `hosts/${hostname}/secrets.yaml` and need path updates.

**Files:**
- Modify: `home/default.nix`
- Modify: `modules/misc/ssh.nix`

- [ ] **Step 1: Update `home/default.nix`**

Change line 14:

```nix
    defaultSopsFile = ../hosts/${hostname}/secrets.yaml;
```

To:

```nix
    defaultSopsFile = ../modules/hosts/${hostname}/secrets.yaml;
```

- [ ] **Step 2: Update `modules/misc/ssh.nix`**

Change line 36:

```nix
          sopsFile = ../../hosts/${hostname}/secrets.yaml;
```

To:

```nix
          sopsFile = ../hosts/${hostname}/secrets.yaml;
```

(From `modules/misc/`, one level up reaches `modules/`, then `hosts/${hostname}/` is a sibling directory.)

- [ ] **Step 3: Commit**

```bash
git add home/default.nix modules/misc/ssh.nix
git commit -m "update sops paths for hosts/ to modules/hosts/ migration"
```

---

### Task 4: Delete `hosts/` directory and verify

Remove remaining files (default.nix wrappers, home.nix, home-packages.nix). Verify no stale references.

**Files:**
- Delete: `hosts/` (entire directory)

- [ ] **Step 1: Verify no remaining references to `hosts/` in nix files**

```bash
grep -r '[\./]hosts/' --include='*.nix' . | grep -v modules/hosts | grep -v '.git/'
```

Expected: No output (all references should now point to `modules/hosts/`).

- [ ] **Step 2: Delete the directory**

```bash
rm -rf hosts/
```

- [ ] **Step 3: Commit**

```bash
git add -A hosts/
git commit -m "delete hosts/ directory; fully consolidated into modules/hosts/"
```

---

### Task 5: Validate the build

**Files:** None (validation only)

- [ ] **Step 1: Check jezrien evaluates**

```bash
nix build .#nixosConfigurations.jezrien.config.system.build.toplevel --dry-run 2>&1 | tail -10
```

Expected: No evaluation errors.

- [ ] **Step 2: Check taln evaluates**

```bash
nix build .#darwinConfigurations.taln.config.system.build.toplevel --dry-run 2>&1 | tail -10
```

Expected: Platform mismatch error only (glibc not available on darwin), not a Nix evaluation error.

- [ ] **Step 3: If errors, fix and re-validate**

Common issues:
- Wrong relative import paths (count the `../` levels carefully — `modules/hosts/jezrien/default.nix` is 3 levels from repo root)
- `import-tree` evaluating underscore files (verify they are actually skipped)
- Missing `inputs` in module scope
- `pkgs` not in scope for `home.packages` (must use `{ pkgs, ... }:` module function pattern)

- [ ] **Step 4: Final commit if any fixes were needed**

```bash
git commit -m "fix build issues from hosts consolidation"
```
