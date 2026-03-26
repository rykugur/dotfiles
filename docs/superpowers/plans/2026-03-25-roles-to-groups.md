# Roles to Groups Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace NixOS-only `roles/` with cross-platform home-manager group modules in `modules/groups/`.

**Architecture:** Group modules are standard `flake.modules.homeManager.*` definitions auto-discovered by `import-tree`. NixOS-specific config moves directly into host configs. Base NixOS defaults from `roles/default.nix` become a new NixOS module.

**Tech Stack:** Nix, home-manager, flake-parts, import-tree

**Spec:** `docs/superpowers/specs/2026-03-25-roles-to-groups-design.md`

---

### File Map

| Action | File | Responsibility |
|--------|------|----------------|
| Create | `modules/groups/developer.nix` | Developer group (merges dev + terminal roles) |
| Create | `modules/groups/gaming.nix` | Gaming group (home-manager portion) |
| Create | `modules/groups/_3dp.nix` | 3D printing group |
| Create | `modules/base/nix-defaults.nix` | Base NixOS config (from roles/default.nix) |
| Modify | `modules/gaming/eve-online.nix` | Remove NixOS wrapper, keep home-manager module |
| Modify | `modules/hosts/jezrien.nix` | Replace roles import, add groups + NixOS modules |
| Modify | `hosts/jezrien/configuration.nix` | Move NixOS enables from roles, remove ryk.roles block |
| Modify | `modules/hosts/taln.nix` | Replace individual imports with developer group |
| Modify | `hosts/taln/home.nix` | Remove packages now provided by developer group |
| Delete | `roles/` (entire directory) | No longer needed |

---

### Task 1: Create `modules/base/nix-defaults.nix`

Extracts the base NixOS config from `roles/default.nix` into a proper dendritic NixOS module.

**Files:**
- Source: `roles/default.nix` (lines 19-91)
- Create: `modules/base/nix-defaults.nix`

- [ ] **Step 1: Create the module**

```nix
{ ... }:
{
  flake.modules.nixos.nix-defaults =
    {
      config,
      lib,
      inputs,
      pkgs,
      ...
    }:
    {
      time.timeZone = "America/Chicago";

      i18n.defaultLocale = "en_US.UTF-8";

      i18n.extraLocaleSettings = {
        LC_ADDRESS = "en_US.UTF-8";
        LC_IDENTIFICATION = "en_US.UTF-8";
        LC_MEASUREMENT = "en_US.UTF-8";
        LC_MONETARY = "en_US.UTF-8";
        LC_NAME = "en_US.UTF-8";
        LC_NUMERIC = "en_US.UTF-8";
        LC_PAPER = "en_US.UTF-8";
        LC_TELEPHONE = "en_US.UTF-8";
        LC_TIME = "en_GB.UTF-8"; # for 24 hour format
      };

      environment.systemPackages = with pkgs; [
        git
        neovim
        nix-search-cli
      ];

      environment.etc = lib.mapAttrs' (name: value: {
        name = "nix/path/${name}";
        value.source = value.flake;
      }) config.nix.registry;

      nix = {
        optimise.automatic = true;
        nixPath = [ "/etc/nix/path" ];
        registry = (lib.mapAttrs (_: flake: { inherit flake; })) (
          (lib.filterAttrs (_: lib.isType "flake")) inputs
        );
        settings = {
          experimental-features = "nix-command flakes pipe-operators";
          auto-optimise-store = true;
        };
      };

      nixpkgs = {
        overlays = [
          inputs.self.overlays.additions
          inputs.self.overlays.modifications
        ];
        config.allowUnfree = true;
      };
    };
}
```

Note: The outer function uses `{ ... }:` matching the established pattern in this codebase (see `modules/shell/carapace.nix`, `modules/gaming/eve-online.nix`). The inner function receives `inputs` and `pkgs` via NixOS `specialArgs`. The overlays reference uses `inputs.self.overlays.*` because `outputs = inputs.self` is set in `specialArgs` (see `modules/hosts/jezrien.nix`).

- [ ] **Step 2: git add the new file**

```bash
git add modules/base/nix-defaults.nix
```

- [ ] **Step 3: Commit**

```bash
git commit -m "add nix-defaults NixOS module from roles/default.nix base config"
```

---

### Task 2: Create `modules/groups/developer.nix`

Merges `roles/dev.nix` and `roles/terminal.nix` into a single cross-platform home-manager group.

**Files:**
- Source: `roles/dev.nix`, `roles/terminal.nix`
- Create: `modules/groups/developer.nix`

- [ ] **Step 1: Create the module**

```nix
{ self, ... }:
{
  flake.modules.homeManager.developer =
    { lib, pkgs, ... }:
    {
      imports = with self.modules.homeManager; [
        # dev
        atuin
        git
        jujutsu
        yaak
        zed-editor

        # terminal
        ghostty
        kitty
        bat
        carapace
        direnv
        starship
        yazi
        zellij
        zoxide
        helix
      ];

      home.packages =
        with pkgs;
        [
          # dev
          bun
          just
          prettierd
          stylua
          vscode
          bruno
          insomnia

          # terminal
          cmatrix
          dnsutils
          dysk
          fzf
          jq
          glow
          ldns
          lsof
          nmap
          p7zip
          silver-searcher
          speedtest-cli
          tree
          unzip
          warp-terminal
          wget
          xz
          zip
          duf
          dust
          gdu
        ]
        ++ lib.optionals pkgs.stdenv.isLinux [
          iftop
          iotop
          lm_sensors
          pciutils
          psmisc
          usbutils
        ];
    };
}
```

Note: Uses `self.modules.homeManager.*` (not `outputs.modules.homeManager.*`) because the outer scope receives `self` from flake-parts. This matches the pattern used in other dendritic modules like `modules/gaming/eve-online.nix`.

- [ ] **Step 2: git add the new file**

```bash
git add modules/groups/developer.nix
```

- [ ] **Step 3: Commit**

```bash
git commit -m "add developer home-manager group (merges dev + terminal roles)"
```

---

### Task 3: Create `modules/groups/gaming.nix`

Home-manager portion of the gaming role.

**Files:**
- Source: `roles/gaming.nix`
- Create: `modules/groups/gaming.nix`

- [ ] **Step 1: Create the module**

```nix
{ self, ... }:
{
  flake.modules.homeManager.gaming =
    { pkgs, ... }:
    {
      imports = with self.modules.homeManager; [
        discord
        lutris
      ];

      home.packages = with pkgs; [
        steamcmd

        protonplus
        protonup-ng
        protonup-qt
        winetricks

        bottles
        dxvk
        gamescope
        heroic
        mangohud
        moonlight-qt
        unixtools.xxd
        vkd3d
        xdelta
      ];
    };
}
```

- [ ] **Step 2: git add the new file**

```bash
git add modules/groups/gaming.nix
```

- [ ] **Step 3: Commit**

```bash
git commit -m "add gaming home-manager group"
```

---

### Task 4: Create `modules/groups/_3dp.nix`

3D printing group, direct port from `roles/3dp.nix`.

**Files:**
- Source: `roles/3dp.nix`
- Create: `modules/groups/_3dp.nix`

- [ ] **Step 1: Create the module**

```nix
{ ... }:
{
  flake.modules.homeManager._3dp =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        qidi-slicer-bin
        freecad-wayland
      ];
    };
}
```

- [ ] **Step 2: git add the new file**

```bash
git add modules/groups/_3dp.nix
```

- [ ] **Step 3: Commit**

```bash
git commit -m "add 3dp home-manager group"
```

---

### Task 5: Update `modules/hosts/jezrien.nix` and simplify `eve-online`

Replace roles import with nix-defaults + ssh NixOS modules. Move group imports into the home-manager imports block. Simplify eve-online at the same time (must happen atomically since jezrien references `self.modules.nixos.eve-online`).

**Files:**
- Modify: `modules/hosts/jezrien.nix`
- Modify: `modules/gaming/eve-online.nix`

- [ ] **Step 1: Simplify `modules/gaming/eve-online.nix`**

Remove the NixOS wrapper. Replace the entire file with just the home-manager module:

```nix
{ self, ... }:
{
  flake.modules.homeManager.eve-online =
    { pkgs, ... }:
    {
      home.packages = [
        pkgs.pyfa
        self.packages.${pkgs.stdenv.hostPlatform.system}.rift-intel-tool
      ];
    };
}
```

- [ ] **Step 2: Replace `../../roles` with NixOS module imports in `modules/hosts/jezrien.nix`**

In the `modules` list, replace line 19 (`../../roles`) with:

```nix
      self.modules.nixos.nix-defaults
      self.modules.nixos.ssh
```

- [ ] **Step 3: Remove `self.modules.nixos.eve-online` from NixOS modules list**

Delete line 30 (`self.modules.nixos.eve-online`) from the modules list.

- [ ] **Step 4: Update home-manager imports block**

Replace the existing `home-manager.users.${username}.imports` block (lines 35-46) with:

```nix
        home-manager.users.${username}.imports = with hmModules; [
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
        ];
```

Note: `eve-online`, `homelab`, and `zen-browser` are added here (previously came via roles). `starcitizen` is NOT listed here — its NixOS module (`self.modules.nixos.starcitizen`, still in the modules list) transitively imports its own home-manager portion.

- [ ] **Step 5: Commit**

```bash
git commit -m "jezrien: replace roles with groups and direct module imports; simplify eve-online"
```

---

### Task 6: Update `hosts/jezrien/configuration.nix`

Move NixOS enables from deleted roles into host config. Remove the `ryk.roles` block.

**Files:**
- Modify: `hosts/jezrien/configuration.nix`

- [ ] **Step 1: Replace the `ryk.roles` block and add missing enables**

In the `ryk` block (starting at line 156), replace:

```nix
    roles = {
      _3dp.enable = true;
      desktop.enable = true; # also enables dev and terminal roles
      gaming.enable = true;
    };
```

With:

```nix
    _1password.enable = true;
    gamemode.enable = true;
    obs-studio.enable = true;
    steam.enable = true;
```

These were previously enabled inside `roles/desktop.nix` and `roles/gaming.nix`.

- [ ] **Step 2: Commit**

```bash
git commit -m "jezrien: move NixOS enables from roles to host config"
```

---

### Task 7: Update `modules/hosts/taln.nix` and clean up `hosts/taln/home.nix`

Replace individual module imports with the `developer` group. Remove packages from `hosts/taln/home.nix` that are now provided by the developer group.

**Files:**
- Modify: `modules/hosts/taln.nix`
- Modify: `hosts/taln/home.nix`

- [ ] **Step 1: Update home-manager imports in `modules/hosts/taln.nix`**

Replace the existing imports block (lines 26-44) with:

```nix
        home-manager.users.${username}.imports = with hmModules; [
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
        ];
```

The following modules from taln's current list are now provided by the `developer` group and should NOT be listed individually: `carapace`, `direnv`, `ghostty`, `git`, `helix`, `jujutsu`, `starship`, `yazi`, `zellij`, `zoxide`.

Note: The developer group will bring in modules taln didn't previously have: `kitty`, `yaak`, `atuin`, `bat` (as a module with extras, replacing the bare package), `zed-editor`. This is intentional — taln now gets the same dev tooling as jezrien.

- [ ] **Step 2: Remove duplicate packages from `hosts/taln/home.nix`**

The following packages in `hosts/taln/home.nix` are now provided by the developer group and should be removed: `bat`, `bun`, `fzf`, `just`, `silver-searcher`, `stylua`.

The remaining packages stay (not in the developer group): `nh`, `nix-prefetch-scripts`, `_1password-cli`, `fd`, `tldr`.

- [ ] **Step 3: Commit**

```bash
git commit -m "taln: replace individual imports with developer group; remove duplicate packages"
```

---

### Task 8: Delete `roles/` directory

All functionality has been migrated. Remove the entire directory.

**Files:**
- Delete: `roles/default.nix`
- Delete: `roles/desktop.nix`
- Delete: `roles/dev.nix`
- Delete: `roles/gaming.nix`
- Delete: `roles/server.nix`
- Delete: `roles/terminal.nix`
- Delete: `roles/3dp.nix`

- [ ] **Step 1: Delete the directory**

```bash
rm -rf roles/
```

- [ ] **Step 2: Commit**

```bash
git add -A roles/
git commit -m "delete roles/ directory; fully replaced by groups"
```

---

### Task 9: Validate the build

Verify both hosts evaluate without errors.

**Files:** None (validation only)

- [ ] **Step 1: Check jezrien evaluates**

```bash
nix build .#nixosConfigurations.jezrien.config.system.build.toplevel --dry-run 2>&1 | tail -10
```

Expected: No evaluation errors (build plan output or "will be built" messages are fine).

- [ ] **Step 2: Check taln evaluates**

```bash
nix build .#darwinConfigurations.taln.config.system.build.toplevel --dry-run 2>&1 | tail -10
```

Expected: A store path (no errors). Note: this may fail if darwin-specific packages aren't available on a Linux host. If so, check for Nix evaluation errors only (not missing-platform errors).

- [ ] **Step 3: If errors, fix and re-validate**

Common issues:
- Duplicate module imports (a module imported both by a group and individually)
- Missing `inputs` in module scope (nix-defaults needs `inputs` via specialArgs)
- Attribute not found errors from removed `ryk.roles.*` options

- [ ] **Step 4: Final commit if any fixes were needed**

```bash
git commit -m "fix build issues from roles-to-groups migration"
```
