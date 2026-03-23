# Dendritic Module Conversion Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Convert all 41 legacy home-manager modules to the flake-parts dendritic pattern, merge 3 cross-variant pairs, update roles, and update host configs.

**Architecture:** Each legacy module (`legacy-modules/home-manager/*.nix`) becomes a flake-parts module (`modules/<category>/<name>.nix`) exposing `flake.modules.homeManager.<name>`. Modules drop `ryk.*.enable` options — opt-in happens by importing the module in the host config. Three modules (ssh, gnome, aerospace) merge their nixos/darwin counterparts into cross-variant files. Roles switch from setting `ryk.*.enable` to importing modules directly.

**Tech Stack:** Nix, flake-parts, home-manager, import-tree

**Spec:** `docs/superpowers/specs/2026-03-23-dendritic-module-conversion-design.md`

---

## Conversion Pattern Reference

Every legacy module follows the same transformation. Use this as the template for all conversions.

**Before (legacy):**
```nix
{ config, lib, pkgs, ... }:
let cfg = config.ryk.<name>;
in {
  options.ryk.<name> = {
    enable = lib.mkEnableOption "Enable <name> home-manager module.";
  };
  config = lib.mkIf cfg.enable {
    programs.<name> = { ... };
  };
}
```

**After (dendritic):**
```nix
{ ... }:
{
  flake.modules.homeManager.<name> = { config, lib, pkgs, ... }: {
    programs.<name> = { ... };
  };
}
```

Key rules:
- Outer function: `{ ... }:` if no flake inputs needed, `{ inputs, ... }:` if inputs required, `{ inputs, self, ... }:` if cross-variant references needed
- Strip `options.ryk.*` block entirely
- Strip `let cfg = config.ryk.<name>; in` binding
- Strip `config = lib.mkIf cfg.enable { ... }` wrapper — the body becomes the module body directly
- Preserve ALL config content (programs, home.packages, home.file, xdg, services, etc.)
- Relative paths: `../../configs/` stays `../../configs/` — both `legacy-modules/home-manager/` and `modules/<category>/` are 2 levels deep from repo root
- For modules with sub-options (ghostty, starsector, git): see special handling in relevant tasks
- Module names with hyphens use quoted attribute names: `flake.modules.homeManager.zen-browser`

---

## Task 1: Convert terminal modules

**Files:**
- Create: `modules/terminal/bat.nix`
- Create: `modules/terminal/btop.nix`
- Create: `modules/terminal/ghostty.nix`
- Create: `modules/terminal/kitty.nix`
- Create: `modules/terminal/wezterm.nix`
- Create: `modules/terminal/tmux.nix`
- Create: `modules/terminal/zellij.nix`
- Create: `modules/terminal/yazi.nix`
- Create: `modules/terminal/ranger.nix`
- Reference: `legacy-modules/home-manager/bat.nix` (source)
- Reference: `legacy-modules/home-manager/btop.nix` (source)
- Reference: `legacy-modules/home-manager/ghostty.nix` (source)
- Reference: `legacy-modules/home-manager/kitty.nix` (source)
- Reference: `legacy-modules/home-manager/wezterm.nix` (source)
- Reference: `legacy-modules/home-manager/tmux.nix` (source)
- Reference: `legacy-modules/home-manager/zellij.nix` (source)
- Reference: `legacy-modules/home-manager/yazi.nix` (source)
- Reference: `legacy-modules/home-manager/ranger.nix` (source)

- [ ] **Step 1: Create `modules/terminal/bat.nix`**

Read `legacy-modules/home-manager/bat.nix` and convert using the pattern. This is a simple module with no special handling.

```nix
{ ... }:
{
  flake.modules.homeManager.bat = { pkgs, ... }: {
    programs.bat = {
      enable = true;
      extraPackages = with pkgs.bat-extras; [ batdiff batman batgrep batwatch ];
    };
  };
}
```

- [ ] **Step 2: Create `modules/terminal/btop.nix`**

```nix
{ ... }:
{
  flake.modules.homeManager.btop = { ... }: {
    programs.btop = {
      enable = true;
      settings = { color_theme = ""; };
    };
  };
}
```

- [ ] **Step 3: Create `modules/terminal/ghostty.nix`**

Special handling: remove `hideWindowDecoration`, `usePredefinedSize` options. Hardcode sensible defaults. Hosts override via `programs.ghostty.settings.*`.

Read `legacy-modules/home-manager/ghostty.nix` for full settings. Convert by:
- Removing the `options.ryk.ghostty` block entirely
- Removing `lib.mkIf cfg.enable` wrapper
- Replacing `${if cfg.hideWindowDecoration then "none" else "auto"}` with `"auto"` (hosts override)
- Removing `lib.mkIf cfg.usePredefinedSize` from window-height/window-width — just omit those settings (hosts add if needed)
- Keeping all other settings as-is

```nix
{ ... }:
{
  flake.modules.homeManager.ghostty = { pkgs, ... }:
    let
      font = "CaskaydiaCove NFM";
    in
    {
      programs.ghostty = {
        enable = true;
        package = if pkgs.stdenv.isDarwin then null else pkgs.ghostty;
        settings = {
          font-family = "${font}";
          font-family-bold = "${font} Bold";
          font-family-italic = "${font} Italic";
          font-family-bold-italic = "${font} Bold Italic";
          font-size = 16;
          theme = "Catppuccin Mocha";
          copy-on-select = "clipboard";
          window-inherit-working-directory = false;
          working-directory = "home";
          window-decoration = "auto";
          app-notifications = false;
          command = "${pkgs.nushell}/bin/nu --login";
          keybind = [
            "alt+h=previous_tab"
            "alt+l=next_tab"
          ];
        };
      };
    };
}
```

- [ ] **Step 4: Create remaining terminal modules**

For each of kitty, wezterm, tmux, zellij, yazi, ranger: read the legacy file, apply the conversion pattern. These are all straightforward — no special options to flatten.

Note for **wezterm**: config is symlinked from `~/.dotfiles/configs/wezterm` — this path is absolute and does NOT need updating.

Note for **tmux**: large config with plugins, keybindings, and Catppuccin theme. Convert verbatim — just strip the enable option wrapper.

Note for **zellij**: very large config with zjstatus plugin. Convert verbatim.

Note for **ranger**: fetches plugins from GitHub via `pkgs.fetchFromGitHub`. Convert verbatim.

- [ ] **Step 5: Verify terminal modules parse**

```bash
git add modules/terminal/*.nix && nix flake check 2>&1 | head -20
```

Expected: no parse errors for the new modules. Legacy modules still active, so no breakage.

- [ ] **Step 6: Commit**

```bash
git add modules/terminal/*.nix
git commit -m "add dendritic terminal modules: bat, btop, ghostty, kitty, wezterm, tmux, zellij, yazi, ranger"
```

---

## Task 2: Convert shell modules

**Files:**
- Create: `modules/shell/fish.nix`
- Create: `modules/shell/starship.nix`
- Create: `modules/shell/atuin.nix`
- Create: `modules/shell/carapace.nix`
- Create: `modules/shell/direnv.nix`
- Create: `modules/shell/zoxide.nix`
- Reference: corresponding files in `legacy-modules/home-manager/`

- [ ] **Step 1: Create all 6 shell modules**

Read each legacy file and apply the conversion pattern. All are straightforward.

Note for **fish**: sources config from `~/.dotfiles/configs/fish/config.fish` — this is an absolute path, no update needed.

Note for **starship**: has conditional shell integration via `config.programs.{fish,nushell,zsh}.enable`. Preserve these — they work fine without a namespace since they reference upstream home-manager options.

Note for **carapace**: has a custom `kubecolor` spec with inline YAML. Convert verbatim.

Note for **atuin**, **direnv**, **zoxide**: simple modules with conditional shell integrations. Convert verbatim.

- [ ] **Step 2: Verify and commit**

```bash
git add modules/shell/*.nix && nix flake check 2>&1 | head -20
git commit -m "add dendritic shell modules: fish, starship, atuin, carapace, direnv, zoxide"
```

---

## Task 3: Convert dev modules

**Files:**
- Create: `modules/dev/git.nix`
- Create: `modules/dev/helix.nix`
- Create: `modules/dev/nvim.nix`
- Create: `modules/dev/zed-editor.nix`
- Create: `modules/dev/jujutsu.nix`
- Reference: corresponding files in `legacy-modules/home-manager/`

Note: `modules/dev/yaak.nix` already exists — don't overwrite it.

- [ ] **Step 1: Create `modules/dev/git.nix`**

Special handling: remove `gitconfig.enable` option. Always apply the gitconfig.

Read `legacy-modules/home-manager/git.nix`. Convert by:
- Removing `options.ryk.git` block
- Removing `lib.mkIf cfg.enable` wrapper
- Removing `lib.mkIf cfg.gitconfig.enable` from `home.file.".gitconfig"` — always apply it
- Update relative path: `../../configs/gitconfig` becomes `../../configs/gitconfig`

```nix
{ ... }:
{
  flake.modules.homeManager.git = { ... }: {
    programs = {
      git = {
        enable = true;
        settings = {
          user = {
            name = "Dusty";
            email = "rollhax@gmail.com";
          };
        };
        lfs.enable = true;
      };
      diff-so-fancy = {
        enable = true;
        enableGitIntegration = true;
      };
      gh = {
        enable = true;
        settings = { git_protocol = "ssh"; };
      };
    };
    home.file.".gitconfig".source = ../../configs/gitconfig;
  };
}
```

- [ ] **Step 2: Create `modules/dev/helix.nix`**

Read `legacy-modules/home-manager/helix.nix`. This is a large module (~441 lines) using `inputs.helix.packages`. Convert by:
- Outer function: `{ inputs, ... }:` to access helix input
- Strip enable option wrapper
- Update relative path: `../../configs/snippets` becomes `../../configs/snippets`
- Preserve all LSP, language, and keybinding config verbatim

- [ ] **Step 3: Create `modules/dev/zed-editor.nix`**

Read `legacy-modules/home-manager/zed-editor.nix`. Convert by:
- Strip enable option wrapper
- Update relative path: `../../configs/snippets` becomes `../../configs/snippets`

- [ ] **Step 4: Create `modules/dev/nvim.nix` and `modules/dev/jujutsu.nix`**

Both are straightforward conversions. nvim symlinks config from `~/.dotfiles/configs/nvim/lazyvim` (absolute path, no update needed).

- [ ] **Step 5: Verify and commit**

```bash
git add modules/dev/git.nix modules/dev/helix.nix modules/dev/nvim.nix modules/dev/zed-editor.nix modules/dev/jujutsu.nix
nix flake check 2>&1 | head -20
git commit -m "add dendritic dev modules: git, helix, nvim, zed-editor, jujutsu"
```

---

## Task 4: Convert desktop modules (including merged gnome and aerospace)

**Files:**
- Create: `modules/desktop/gnome.nix` (MERGED: nixos + home-manager)
- Create: `modules/desktop/aerospace.nix` (MERGED: darwin + home-manager)
- Create: `modules/desktop/fuzzel.nix`
- Create: `modules/desktop/walker.nix`
- Create: `modules/desktop/flameshot.nix`
- Create: `modules/desktop/swappy.nix`
- Create: `modules/desktop/swaylock.nix`
- Create: `modules/desktop/nautilus.nix`
- Create: `modules/desktop/nemo.nix`
- Create: `modules/desktop/thunar.nix`
- Create: `modules/desktop/albert.nix`
- Reference: `legacy-modules/home-manager/gnome.nix`, `legacy-modules/nixos/gnome.nix`
- Reference: `legacy-modules/home-manager/aerospace.nix`, `legacy-modules/darwin/aerospace.nix`
- Reference: corresponding files in `legacy-modules/home-manager/`

- [ ] **Step 1: Create `modules/desktop/gnome.nix` (merged)**

Merge `legacy-modules/nixos/gnome.nix` (system services) + `legacy-modules/home-manager/gnome.nix` (dconf settings). The nixos variant auto-imports the HM variant.

```nix
{ self, ... }:
{
  flake.modules.nixos.gnome = { config, pkgs, username, ... }: {
    environment.systemPackages = with pkgs; [
      gnome-tweaks
      gnomeExtensions.dash-to-dock
    ];
    services = {
      gnome.gnome-browser-connector.enable = true;
      xserver = {
        enable = true;
        displayManager.gdm.enable = true;
        desktopManager.gnome.enable = true;
      };
    };
    home-manager.users.${username}.imports = [ self.modules.homeManager.gnome ];
  };

  flake.modules.homeManager.gnome = { lib, ... }: {
    dconf.settings = {
      "org/gnome/mutter" = { edge-tiling = true; };
      "org/gnome/desktop/interface" = {
        color-scheme = "prefer-dark";
        enable-hot-corners = false;
      };
      "org/gnome/desktop/peripherals/keyboard" = {
        numlock-state = true;
      };
      "org/gnome/desktop/sound" = {
        event-sounds = false;
        theme-name = "__custom";
      };
      "org/gnome/desktop/default-applications/terminal" = {
        exec = "ghostty";
      };
    };
    xdg.mimeApps.defaultApplications = {
      "image/jpeg" = [ "org.gnome.Loupe.desktop" ];
      "image/png" = [ "org.gnome.Loupe.desktop" ];
    };
  };
}
```

Note: Read the actual legacy gnome HM module for exact dconf settings — the above is illustrative. Copy verbatim.

- [ ] **Step 2: Create `modules/desktop/aerospace.nix` (merged)**

Merge `legacy-modules/darwin/aerospace.nix` (system defaults) + `legacy-modules/home-manager/aerospace.nix` (keybindings).

```nix
{ self, ... }:
{
  flake.modules.darwin.aerospace = { username, ... }: {
    system.defaults = {
      dock.expose-group-apps = true;
      spaces.spans-displays = true;
    };
    home-manager.users.${username}.imports = [ self.modules.homeManager.aerospace ];
  };

  flake.modules.homeManager.aerospace = { ... }: {
    programs.aerospace = {
      enable = true;
      userSettings = {
        # ... copy full keybinding config from legacy HM module verbatim ...
      };
    };
  };
}
```

- [ ] **Step 3: Create remaining desktop modules**

For fuzzel, walker, flameshot, swaylock, nautilus, nemo, thunar, albert: read each legacy file and apply the conversion pattern.

Note for **swappy**: uses `home.file` with source from `../../configs/swappy` — update to `../../configs/swappy`.

Note for **albert**: fetches a Dracula theme from GitHub. Convert verbatim.

Note for **swaylock**: large color config. Convert verbatim.

- [ ] **Step 4: Verify and commit**

```bash
git add modules/desktop/*.nix && nix flake check 2>&1 | head -20
git commit -m "add dendritic desktop modules: gnome, aerospace, fuzzel, walker, flameshot, swappy, swaylock, nautilus, nemo, thunar, albert"
```

---

## Task 5: Convert browser modules

**Files:**
- Create: `modules/browser/zen-browser.nix` (renamed from browser.nix)
- Create: `modules/browser/firefox.nix`
- Reference: `legacy-modules/home-manager/browser.nix`
- Reference: `legacy-modules/home-manager/firefox.nix`

- [ ] **Step 1: Create `modules/browser/zen-browser.nix`**

Renamed from `browser.nix`. Needs `{ inputs, ... }:` for zen-browser input. Remove google-chrome package (stays in `hosts/jezrien/home-packages.nix`). Self-imports zen-browser's HM module.

```nix
{ inputs, ... }:
{
  flake.modules.homeManager.zen-browser = { pkgs, ... }: {
    imports = [ inputs.zen-browser.homeModules.default ];

    programs.zen-browser = {
      enable = true;
      package = inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default;
    };

    stylix.targets.zen-browser.enable = false;

    xdg = {
      enable = true;
      mimeApps = {
        enable = true;
        defaultApplications =
          let zenDesktop = "zen-beta.desktop";
          in {
            "application/pdf" = [ zenDesktop ];
            "text/html" = [ zenDesktop ];
            "x-scheme-handler/about" = [ zenDesktop ];
            "x-scheme-handler/unknown" = [ zenDesktop ];
            "x-scheme-handler/chrome" = [ zenDesktop ];
            "application/x-extension-htm" = [ zenDesktop ];
            "application/x-extension-html" = [ zenDesktop ];
            "application/x-extension-shtml" = [ zenDesktop ];
            "application/xhtml+xml" = [ zenDesktop ];
            "application/x-extension-xhtml" = [ zenDesktop ];
            "application/x-extension-xht" = [ zenDesktop ];
            "x-scheme-handler/http" = zenDesktop;
            "x-scheme-handler/https" = zenDesktop;
          };
      };
    };
  };
}
```

- [ ] **Step 2: Add google-chrome to `hosts/jezrien/home-packages.nix`**

Add `google-chrome` to the packages list in `hosts/jezrien/home-packages.nix`.

- [ ] **Step 3: Create `modules/browser/firefox.nix`**

Read `legacy-modules/home-manager/firefox.nix`. Note: the legacy module references `cfg.ArcWTF.enable` and `cfg.mime.enable` but these options are NOT defined in the options block — this appears to be broken/unused code. Convert by:
- Removing the ArcWTF conditional (`lib.mkIf cfg.ArcWTF.enable`) — either always include ArcWTF or remove it. Since the options don't exist, this code was never activated. Remove the ArcWTF home.file and the related profile settings.
- Removing the mime conditional (`lib.mkIf cfg.mime.enable`) — same issue. Remove the xdg mimeApps block (zen-browser handles mime defaults anyway).
- Keep the ArcWTF derivation and core firefox config.

- [ ] **Step 4: Verify and commit**

```bash
git add modules/browser/*.nix hosts/jezrien/home-packages.nix && nix flake check 2>&1 | head -20
git commit -m "add dendritic browser modules: zen-browser (renamed), firefox; move chrome to jezrien packages"
```

---

## Task 6: Convert audio modules + move pipewire

**Files:**
- Create: `modules/audio/easyeffects.nix`
- Move: `modules/nixos/pipewire.nix` -> `modules/audio/pipewire.nix`
- Reference: `legacy-modules/home-manager/easyeffects.nix`

- [ ] **Step 1: Create `modules/audio/easyeffects.nix`**

Update relative paths: `../../configs/easyeffects/` becomes `../../configs/easyeffects/`.

```nix
{ ... }:
{
  flake.modules.homeManager.easyeffects = { ... }: {
    services.easyeffects.enable = true;
    home.file = {
      ".config/easyeffects/input/input.json".source =
        ../../configs/easyeffects/input/improved-microphone-male-voices.json;
      ".config/easyeffects/output/output.json".source =
        ../../configs/easyeffects/output/heavy-bass.json;
    };
  };
}
```

- [ ] **Step 2: Move pipewire**

```bash
mkdir -p modules/audio
git mv modules/nixos/pipewire.nix modules/audio/pipewire.nix
```

No content changes needed — already dendritic. Verify `modules/nixos/` is now empty (or has other files) and clean up if needed.

- [ ] **Step 3: Update jezrien host config**

In `modules/hosts/jezrien.nix`, change `self.modules.nixos.pipewire` — this reference is by attribute path, not file path, so it still works after the move since `import-tree` discovers by file but the attribute is set by the module content. **No change needed** — the module still sets `flake.modules.nixos.pipewire` regardless of file location.

- [ ] **Step 4: Verify and commit**

```bash
git add modules/audio/*.nix && nix flake check 2>&1 | head -20
git commit -m "add dendritic easyeffects module; move pipewire to audio category"
```

---

## Task 7: Convert gaming modules

**Files:**
- Create: `modules/gaming/starsector.nix`
- Create: `modules/gaming/lutris.nix`
- Reference: `legacy-modules/home-manager/starsector.nix`
- Reference: `legacy-modules/home-manager/lutris.nix`

Note: `modules/gaming/eve-online.nix` and `modules/gaming/starcitizen.nix` already exist — don't overwrite.

- [ ] **Step 1: Create `modules/gaming/starsector.nix`**

Special handling: remove `mods.enable` option — always link mods.

Read `legacy-modules/home-manager/starsector.nix`. Convert by:
- Removing `options.ryk.starsector` block
- Removing `lib.mkIf cfg.enable` wrapper
- Removing `lib.mkIf cfg.mods.enable` from `home.file` — always link mods
- Keeping all fetchzip derivations verbatim

- [ ] **Step 2: Create `modules/gaming/lutris.nix`**

Read `legacy-modules/home-manager/lutris.nix`. Convert verbatim. Note: uses `osConfig.programs.steam.package` which requires being on a NixOS host with steam enabled. This is fine — lutris is only used on jezrien.

- [ ] **Step 3: Verify and commit**

```bash
git add modules/gaming/starsector.nix modules/gaming/lutris.nix && nix flake check 2>&1 | head -20
git commit -m "add dendritic gaming modules: starsector, lutris"
```

---

## Task 8: Convert social and misc modules

**Files:**
- Create: `modules/social/discord.nix`
- Create: `modules/misc/ssh.nix` (MERGED: nixos + home-manager)
- Create: `modules/misc/homelab.nix`
- Create: `modules/misc/keebs.nix`
- Create: `modules/misc/vicinae.nix`
- Reference: corresponding files in `legacy-modules/home-manager/`
- Reference: `legacy-modules/nixos/ssh.nix`

- [ ] **Step 1: Create `modules/social/discord.nix`**

Simple module — just installs discord and betterdiscordctl.

- [ ] **Step 2: Create `modules/misc/ssh.nix` (merged)**

Merge `legacy-modules/nixos/ssh.nix` + `legacy-modules/home-manager/ssh.nix`. This is the most complex merge.

```nix
{ inputs, self, ... }:
{
  flake.modules.nixos.ssh = { username, ... }: {
    services.openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "no";
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
      };
    };
    users.users.${username}.openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAgLk3xlBbjNte2VW4ZE6ewngB07bZ1MdkOBnJFFnzQV"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO+urk8awyDQhOmONXIsAcHzaIlvHSiTD4rL/5GAHo6D"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMKORtO51gYjGRuP3pP/paOe8NcBfQvrcZLSSwc4bqpT"
    ];
    home-manager.users.${username}.imports = [ self.modules.homeManager.ssh ];
  };

  flake.modules.homeManager.ssh = { config, inputs, hostname, pkgs, ... }: {
    imports = [ inputs.sops-nix.homeManagerModules.sops ];

    home.packages = with pkgs; [ age sops ];

    sops.secrets.ssh_private_key = {
      sopsFile = ../../hosts/${hostname}/secrets.yaml;
      path = "${config.home.homeDirectory}/.ssh/id_ed25519";
      mode = "0400";
    };

    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;
      matchBlocks = {
        "*" = {
          forwardAgent = false;
          addKeysToAgent = "no";
          compression = false;
          serverAliveInterval = 0;
          serverAliveCountMax = 3;
          hashKnownHosts = false;
          userKnownHostsFile = "~/.ssh/known_hosts";
          controlMaster = "no";
          controlPath = "~/.ssh/master-%r@%n:%p";
          controlPersist = "no";
        };
        "*.local.ryk.sh" = {
          identityFile = "~/.ssh/id_ed25519";
          identitiesOnly = true;
          forwardAgent = true;
        };
        "github.com" = {
          identityFile = "~/.ssh/id_ed25519";
          identitiesOnly = true;
          forwardAgent = false;
        };
      };
    };
  };
}
```

**Note:** Both `modules/misc/` and `legacy-modules/home-manager/` are 2 levels deep, so relative paths stay the same (`../../hosts/...`). Sops paths are evaluated relative to the file — verify during testing.

- [ ] **Step 3: Create `modules/misc/homelab.nix`, `modules/misc/keebs.nix`, `modules/misc/vicinae.nix`**

**homelab**: kubernetes tools + k9s + kubecolor. Straightforward conversion.

**keebs**: fetches Via configs from GitHub + local file. Update relative path for local config: check if `../../legacy-modules/home-manager/keebs/kb16-01.json` exists or similar. Read the legacy module to find exact path.

**vicinae**: has custom derivation + systemd service + `autoStart` option. Convert by:
- Removing `enable` and `autoStart` options
- Always enabling the systemd service (set `WantedBy = [ "graphical-session.target" ]` unconditionally)
- Note: this is a behavioral change — legacy module required `autoStart = true` explicitly. Since importing the module means you want vicinae, auto-starting the daemon is reasonable. Add a comment in the converted module.

- [ ] **Step 4: Verify and commit**

```bash
git add modules/social/*.nix modules/misc/*.nix && nix flake check 2>&1 | head -20
git commit -m "add dendritic social and misc modules: discord, ssh (merged), homelab, keebs, vicinae"
```

---

## Task 9: Update roles

**Files:**
- Modify: `roles/terminal.nix`
- Modify: `roles/desktop.nix`
- Modify: `roles/dev.nix`
- Modify: `roles/gaming.nix`

**Depends on:** Tasks 1-8 (all dendritic modules must exist)

- [ ] **Step 1: Update `roles/terminal.nix`**

Replace `ryk.*` enables with imports. The role needs access to `config.flake.modules.homeManager` which is available because the role is loaded inside `nixpkgs.lib.nixosSystem` which includes flake-parts modules.

**However**, roles are loaded via `../../roles` from the host config, which means they're NixOS modules — they don't have direct access to `config.flake.modules.homeManager`. The roles need the modules passed in via specialArgs or another mechanism.

**Solution:** Roles will receive `self` via specialArgs (already available as `outputs` in specialArgs). Use `outputs.modules.homeManager.*`.

Before:
```nix
home-manager.users.${username} = {
  ryk = {
    ghostty.enable = true;
    kitty.enable = true;
    bat.enable = true;
    carapace.enable = true;
    direnv.enable = true;
    starship.enable = true;
    yazi.enable = true;
    zellij.enable = true;
    zoxide.enable = true;
    helix.enable = true;
  };
};
```

After:
```nix
home-manager.users.${username} = {
  imports = with outputs.modules.homeManager; [
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
};
```

Add `outputs` to the function args: `{ config, lib, pkgs, username, outputs, ... }:`

Keep `home.packages` as-is.

- [ ] **Step 2: Update `roles/desktop.nix`**

Two changes:
1. Replace HM-level `ryk.*` enables with imports
2. Replace NixOS-level `ryk.ssh.enable` with nixos module import

Before:
```nix
ryk = {
  roles = { dev.enable = true; terminal.enable = true; };
  _1password.enable = true;
  ssh.enable = true;  # NixOS-level — must change
};
home-manager.users.${username} = {
  ryk = {
    browser.enable = true;
    homelab.enable = true;
    ssh.enable = true;  # HM-level
  };
};
```

After:
```nix
ryk = {
  roles = { dev.enable = true; terminal.enable = true; };
  _1password.enable = true;
  # ssh.enable removed — handled by importing nixos module below
};
# Import the merged nixos ssh module (which transitively imports HM ssh)
imports = [ outputs.modules.nixos.ssh ];
home-manager.users.${username} = {
  imports = with outputs.modules.homeManager; [
    zen-browser
    homelab
    # ssh HM side is imported transitively via nixos.ssh
  ];
};
```

Add `outputs` to function args.

- [ ] **Step 3: Update `roles/dev.nix`**

Replace HM `ryk.*` enables with imports.

After:
```nix
home-manager.users.${username} = {
  imports = with outputs.modules.homeManager; [
    atuin
    git
    jujutsu
    zed-editor
  ];
  home.packages = with pkgs; [ ... ];  # keep as-is
};
```

Add `outputs` to function args.

- [ ] **Step 4: Update `roles/gaming.nix`**

Replace HM `ryk.*` enables with imports. Keep NixOS-level `ryk.*` options (gamemode, obs-studio, steam) as-is.

After:
```nix
home-manager.users.${username} = {
  imports = with outputs.modules.homeManager; [
    discord
    lutris
  ];
  home.packages = with pkgs; [ ... ];  # keep as-is
};
```

Add `outputs` to function args.

- [ ] **Step 5: Verify roles compile**

```bash
nix flake check 2>&1 | head -30
```

At this point both legacy and dendritic modules coexist. Roles now import dendritic modules but legacy modules are still loaded (with their options unused). This should work — the legacy `ryk.*.enable` options default to `false`.

- [ ] **Step 6: Commit**

```bash
git add roles/*.nix
git commit -m "update roles to import dendritic modules instead of ryk.*.enable"
```

---

## Task 10: Update host configs

**Files:**
- Modify: `modules/hosts/jezrien.nix`
- Modify: `hosts/jezrien/home.nix`
- Modify: `modules/hosts/taln.nix`
- Modify: `hosts/taln/home.nix`
- Modify: `hosts/nixy/configuration.nix`

**Depends on:** Tasks 1-9

- [ ] **Step 1: Update `modules/hosts/jezrien.nix`**

- **Keep** `../../legacy-modules/nixos` import — it loads 12+ other nixos modules (1password, steam, gamemode, etc.) that are out of scope. The ssh.nix and gnome.nix removals are handled in Task 11 by editing `legacy-modules/nixos/default.nix`.
- **Keep** `../../legacy-modules` import — it loads `legacy-modules/default.nix` which chains to desktop/, dev/, gaming/, misc/, virtualization/ — all out of scope. (It does NOT import home-manager/ — that's loaded separately via `hosts/jezrien/home.nix`.)
- Add `self.modules.nixos.ssh` and `self.modules.nixos.gnome` to module list
- Expand the HM imports list to include ALL converted modules that jezrien uses

Read `hosts/jezrien/home.nix` to determine which modules jezrien enables (via `ryk.*` and via roles). Jezrien enables:
- Via roles (terminal + desktop + dev + gaming): all modules in those roles
- Directly in home.nix: btop, keebs, ghostty (hideWindowDecoration), starsector (mods), swappy, wezterm
- Already dendritic: ccstatusline, claude-code, nushell, opencode, television

The full HM imports list for jezrien:
```nix
home-manager.users.${username}.imports = with hmModules; [
  # from terminal role
  ghostty kitty bat carapace direnv starship yazi zellij zoxide helix
  # from desktop role
  zen-browser homelab
  # from dev role
  atuin git jujutsu zed-editor
  # from gaming role
  discord lutris
  # from home.nix direct
  btop keebs starsector swappy wezterm
  # already dendritic
  ccstatusline claude-code nushell opencode television
];
```

**Wait** — if roles already handle the imports via `outputs.modules.homeManager.*`, and jezrien loads roles, then modules imported by roles don't need to be duplicated in the host config. The host config only needs modules NOT covered by roles.

So jezrien's HM imports in `modules/hosts/jezrien.nix` should only include:
```nix
home-manager.users.${username}.imports = with hmModules; [
  # host-specific (not in any role)
  btop keebs starsector swappy wezterm
  # already dendritic
  ccstatusline claude-code nushell opencode television
];
```

Roles handle the rest.

**However**, we need to verify: do roles import into `home-manager.users.${username}` correctly when loaded as NixOS modules? Yes — roles are NixOS modules that set `home-manager.users.${username}.imports`, which home-manager merges.

- [ ] **Step 2: Update `hosts/jezrien/home.nix`**

- Remove `../../legacy-modules/home-manager` import
- Remove all `ryk.*` options (they're now handled by imports in roles and host config)
- Keep: `../../home` import, `./home-packages.nix` import, `nixpkgs.config`, `sops.secrets`, `home.packages`, other settings
- Add per-host overrides for ghostty:

```nix
{ pkgs, ... }:
{
  imports = [
    ../../home
    ./home-packages.nix
  ];

  nixpkgs.config.permittedInsecurePackages = [
    "electron-25.9.0"
    "nexusmods-app-unfree-0.21.1"
  ];

  sops.secrets = {
    homelab_ssh_private_key = {
      sopsFile = ../../hosts/jezrien/secrets.yaml;
    };
  };

  home.packages = [
    pkgs.beyond-all-reason
    pkgs.kalker
  ];

  # Per-host overrides
  programs.ghostty.settings.window-decoration = "none";

  programs.home-manager.enable = true;
  systemd.user.startServices = "sd-switch";
  home.stateVersion = "23.11";
}
```

- [ ] **Step 3: Check if `legacy-modules/default.nix` or `legacy-modules/nixos/default.nix` import other modules beyond ssh/gnome**

Read `legacy-modules/default.nix` and `legacy-modules/nixos/default.nix` to see if removing these imports from jezrien breaks anything. If there are other nixos legacy modules still in use, keep the `../../legacy-modules/nixos` import but remove the specific ssh.nix and gnome.nix from it.

- [ ] **Step 4: Update `modules/hosts/taln.nix`**

Add HM module imports. Taln currently uses selective imports in `hosts/taln/home.nix`. Move these to `modules/hosts/taln.nix`:

```nix
{ config, inputs, self, ... }:
let
  username = "dusty";
  hmModules = config.flake.modules.homeManager;
in
{
  flake.darwinConfigurations.taln = inputs.nix-darwin.lib.darwinSystem {
    modules = [
      # ../../legacy-modules/darwin  # REMOVE — only contained aerospace.nix which is now dendritic
      ../../hosts/taln/configuration.nix
      inputs.stylix.darwinModules.stylix
      self.modules.darwin.fonts
      self.modules.darwin.stylix
      # self.modules.darwin.aerospace  # uncomment when aerospace is enabled

      {
        home-manager.users.${username}.imports = with hmModules; [
          carapace
          ccstatusline
          claude-code
          direnv
          ghostty
          git
          helix
          homelab
          jujutsu
          nushell
          opencode
          ssh
          starship
          television
          yazi
          zellij
          zoxide
        ];
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

- [ ] **Step 5: Update `hosts/taln/home.nix`**

Remove all legacy imports and `ryk.*` options. Keep only base imports and host-specific config:

```nix
{ pkgs, ... }:
{
  imports = [
    ../../home
  ];

  home.packages = with pkgs; [
    nh
    nix-prefetch-scripts
    _1password-cli
    bat
    fd
    fzf
    just
    silver-searcher
    stylua
    tldr
  ];

  programs.home-manager.enable = true;
  # Remove systemd.user.startServices — taln is macOS, this is Linux-only
  home.stateVersion = "23.11";
}
```

- [ ] **Step 6: Update `hosts/nixy/configuration.nix`**

Replace legacy ssh import with dendritic module. `self` is not in specialArgs for nixy — need to pass it or use `outputs` (which is `inputs.self`).

Change:
```nix
../../legacy-modules/nixos/ssh.nix
```
To:
```nix
outputs.modules.nixos.ssh
```

Remove `ryk.ssh.enable = true;` line.

Verify `outputs` is in specialArgs for nixy. Check `modules/hosts/` for a nixy config or wherever nixy's nixosSystem is defined.

- [ ] **Step 7: Verify full build**

```bash
nix flake check 2>&1 | head -30
nix eval .#nixosConfigurations.jezrien.config.system.build.toplevel --no-build 2>&1 | tail -5
nix eval .#darwinConfigurations.taln.config.system.build.toplevel --no-build 2>&1 | tail -5
```

- [ ] **Step 8: Commit**

```bash
git add modules/hosts/*.nix hosts/jezrien/home.nix hosts/taln/home.nix hosts/nixy/configuration.nix
git commit -m "update host configs and nixy to use dendritic modules"
```

---

## Task 11: Delete legacy files

**Files:**
- Delete: `legacy-modules/home-manager/` (all 42 files including default.nix)
- Delete: `legacy-modules/nixos/ssh.nix`
- Delete: `legacy-modules/nixos/gnome.nix`
- Delete: `legacy-modules/darwin/aerospace.nix`
- Modify: `legacy-modules/nixos/default.nix` (remove ssh.nix and gnome.nix imports)
- Modify: `legacy-modules/darwin/default.nix` (remove aerospace.nix import)

**Depends on:** Task 10

- [ ] **Step 1: Check remaining imports**

Before deleting, verify nothing still references the legacy home-manager directory:

```bash
grep -r "legacy-modules/home-manager" --include="*.nix" .
```

Should return no results (after Task 10 updates).

Also check for remaining references to deleted nixos/darwin files:

```bash
grep -r "legacy-modules/nixos/ssh\|legacy-modules/nixos/gnome\|legacy-modules/darwin/aerospace" --include="*.nix" .
```

- [ ] **Step 2: Update `legacy-modules/nixos/default.nix`**

Remove `./ssh.nix` and `./gnome.nix` from imports list (if they're listed there).

- [ ] **Step 3: Update `legacy-modules/darwin/default.nix`**

Remove `./aerospace.nix` from imports list.

- [ ] **Step 4: Delete legacy home-manager directory**

```bash
git rm -r legacy-modules/home-manager/
git rm legacy-modules/nixos/ssh.nix legacy-modules/nixos/gnome.nix
git rm legacy-modules/darwin/aerospace.nix
```

- [ ] **Step 5: Verify everything still builds**

```bash
nix flake check 2>&1 | head -30
```

- [ ] **Step 6: Commit**

```bash
git commit -m "remove legacy home-manager modules and merged nixos/darwin files"
```

---

## Task 12: Final verification and cleanup

**Depends on:** Task 11

- [ ] **Step 1: Full flake check**

```bash
nix flake check
```

- [ ] **Step 2: Verify module attribute paths exist**

```bash
nix eval .#modules.homeManager --apply 'x: builtins.attrNames x' 2>&1
```

Should list all converted module names.

- [ ] **Step 3: Verify host configs evaluate**

```bash
nix eval .#nixosConfigurations.jezrien.config.system.build.toplevel --no-build
nix eval .#darwinConfigurations.taln.config.system.build.toplevel --no-build
```

- [ ] **Step 4: Check for orphaned references**

```bash
grep -r "ryk\.\(bat\|btop\|ghostty\|kitty\|wezterm\|tmux\|zellij\|yazi\|ranger\|fish\|starship\|atuin\|carapace\|direnv\|zoxide\|git\|helix\|nvim\|zed-editor\|jujutsu\|fuzzel\|walker\|flameshot\|swappy\|swaylock\|nautilus\|nemo\|thunar\|gnome\|albert\|browser\|firefox\|easyeffects\|starsector\|lutris\|discord\|ssh\|homelab\|keebs\|vicinae\|aerospace\)" --include="*.nix" . | grep -v "^Binary"
```

Any remaining references are orphaned `ryk.*` options that need cleanup.

- [ ] **Step 5: Commit any cleanup**

```bash
git add -A && git commit -m "cleanup: remove orphaned ryk.* references"
```
