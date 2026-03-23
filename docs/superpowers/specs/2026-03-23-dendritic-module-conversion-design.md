# Convert Legacy Home-Manager Modules to Dendritic Pattern

## Context

The dotfiles repo has 41 legacy home-manager modules in `legacy-modules/home-manager/` using the traditional NixOS module pattern (`options.ryk.<name>.enable` + `config = lib.mkIf`). The repo has been gradually adopting a new "dendritic" pattern using flake-parts' `flake.modules` system under `modules/`. This spec covers converting all 41 legacy home-manager modules, merging 3 nixos/darwin counterparts, and updating the roles system.

## Module Structure

Each converted module becomes a flake-parts module file under `modules/<category>/<name>.nix`:

```nix
{ inputs, ... }:    # or { ... }: if no flake inputs needed
{
  flake.modules.homeManager.<name> = { config, lib, pkgs, ... }: {
    imports = [ inputs.foo.homeModules.default ];  # if needed
    programs.<name> = { ... };
    home.packages = [ ... ];
  };
}
```

### Key decisions

- **No `enable` options.** Opt-in is handled by importing the module in the host config.
- **No custom namespace.** No `ryk.*` options for these modules. Use upstream `programs.*` / `home.*` options directly. Per-host overrides go in the host config.
- **External dependencies self-contained.** Modules import their own flake home-manager modules internally (e.g., zen-browser imports `inputs.zen-browser.homeModules.default`).
- **Cross-variant in one file.** Modules that need both nixos/darwin and home-manager config define `flake.modules.nixos.<name>` (or `flake.modules.darwin.<name>`) and `flake.modules.homeManager.<name>` in the same file. The system variant pulls in the homeManager variant via `self.modules.homeManager.<name>`.
- **Auto-discovery.** Any `.nix` file added under `modules/` is automatically imported by `(inputs.import-tree ./modules)` in `flake.nix` — no manual registration needed.

## Category Organization

All modules live under `modules/` and are auto-discovered by `import-tree`. Directory structure reflects domain, not module type (no `modules/nixos/` or `modules/home-manager/` directories).

| Category | Modules |
|----------|---------|
| `terminal/` | ghostty, kitty, wezterm, tmux, zellij, bat, btop, yazi, ranger |
| `shell/` | fish, starship, atuin, carapace, direnv, zoxide |
| `dev/` | git, helix, nvim, zed-editor, jujutsu |
| `desktop/` | aerospace, fuzzel, walker, flameshot, swappy, swaylock, nautilus, nemo, thunar, gnome, albert |
| `browser/` | zen-browser, firefox |
| `audio/` | pipewire, easyeffects |
| `gaming/` | starsector, lutris |
| `social/` | discord |
| `misc/` | ssh, homelab, keebs, vicinae |

### Existing modules that move

- `modules/nixos/pipewire.nix` -> `modules/audio/pipewire.nix` (no structural changes needed, already dendritic)

## Merged Module Pairs

Three modules currently split across legacy directories get merged into single dendritic files with both variants:

### ssh (`legacy-modules/nixos/ssh.nix` + `legacy-modules/home-manager/ssh.nix`)

```nix
# modules/misc/ssh.nix
{ inputs, self, ... }:
{
  flake.modules.nixos.ssh = { config, lib, username, ... }:
    {
      services.openssh = {
        enable = true;
        settings = { PermitRootLogin = "no"; PasswordAuthentication = false; ... };
      };
      users.users.${username}.openssh.authorizedKeys.keys = [ ... ];
      home-manager.users.${username}.imports = [ self.modules.homeManager.ssh ];
    };

  flake.modules.homeManager.ssh = { config, hostname, ... }: {
    imports = [ inputs.sops-nix.homeManagerModules.sops ];
    # client config, identity files, sops secrets
  };
}
```

Note: The nixos variant uses `username` from specialArgs (as the legacy module does today), not `config.ryk.username`, to avoid a hard dependency on `self.modules.nixos.meta`.

### gnome (`legacy-modules/nixos/gnome.nix` + `legacy-modules/home-manager/gnome.nix`)

Merged into `modules/desktop/gnome.nix` with `flake.modules.nixos.gnome` + `flake.modules.homeManager.gnome`.

### aerospace (`legacy-modules/darwin/aerospace.nix` + `legacy-modules/home-manager/aerospace.nix`)

Merged into `modules/desktop/aerospace.nix` with `flake.modules.darwin.aerospace` + `flake.modules.homeManager.aerospace`.

## Roles Updates

Roles (`roles/terminal.nix`, `roles/desktop.nix`, `roles/dev.nix`, `roles/gaming.nix`) currently set `ryk.<name>.enable = true` for home-manager modules inside `home-manager.users.${username}`. Since converted modules no longer have `enable` options, roles must be updated to import modules directly instead.

Before (legacy):
```nix
# roles/terminal.nix
home-manager.users.${username} = {
  ryk = {
    ghostty.enable = true;
    bat.enable = true;
    helix.enable = true;
    # ...
  };
};
```

After (dendritic):
```nix
# roles/terminal.nix
home-manager.users.${username} = {
  imports = with config.flake.modules.homeManager; [
    ghostty
    bat
    helix
    # ...
  ];
};
```

Roles continue to set `ryk.*` options for nixos-level legacy modules that are out of scope (e.g., `ryk._1password.enable` in `roles/desktop.nix`). These will be addressed when the remaining legacy modules are converted.

Since `legacy-modules/nixos/ssh.nix` is being merged into the dendritic `modules/misc/ssh.nix`, the NixOS-level `ryk.ssh.enable` in `roles/desktop.nix` must also be converted — replace it with an import of `self.modules.nixos.ssh` in the role's module list.

**Affected roles and their home-manager `ryk.*` references to convert:**

| Role | HM modules to convert to imports |
|------|----------------------------------|
| `terminal` | ghostty, kitty, bat, carapace, direnv, starship, yazi, zellij, zoxide, helix |
| `desktop` | browser (-> zen-browser), homelab, ssh (HM side). Also replace NixOS-level `ryk.ssh.enable` with `self.modules.nixos.ssh` import |
| `dev` | atuin, git, jujutsu, zed-editor |
| `gaming` | discord, lutris |

## Host Config Changes

### jezrien (NixOS)

`modules/hosts/jezrien.nix` drops the bulk `../../legacy-modules` import (once all modules are converted) and references modules explicitly:

```nix
let hmModules = config.flake.modules.homeManager;
in {
  flake.nixosConfigurations.jezrien = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      # nixos-level dendritic modules
      self.modules.nixos.ssh
      self.modules.nixos.gnome
      # ...legacy nixos modules still being migrated...

      {
        home-manager.users.${username}.imports = with hmModules; [
          bat btop ghostty git helix fish starship
          # ... all converted modules
        ];
      }
    ];
  };
}
```

Per-host overrides sit alongside:

```nix
{
  home-manager.users.${username} = {
    imports = with hmModules; [ ghostty ];
    programs.ghostty.settings.window-decoration = "none";
  };
}
```

### taln (Darwin)

Taln currently uses a different pattern: `hosts/taln/home.nix` selectively imports legacy modules via relative paths and sets `ryk.*` options directly. The conversion moves all module imports into `modules/hosts/taln.nix` (consistent with jezrien) and `hosts/taln/home.nix` becomes a thin file with only host-specific packages and settings.

Before:
```nix
# hosts/taln/home.nix
imports = [
  ../../legacy-modules/home-manager/ghostty.nix
  ../../legacy-modules/home-manager/git.nix
  # ...12 more legacy imports...
  outputs.modules.homeManager.claude-code
  # ...
];
ryk = {
  ghostty.enable = true;
  git = { enable = true; gitconfig.enable = true; };
  # ...
};
```

After:
```nix
# modules/hosts/taln.nix
flake.darwinConfigurations.taln = inputs.nix-darwin.lib.darwinSystem {
  modules = [
    ../../hosts/taln/configuration.nix
    self.modules.darwin.aerospace
    self.modules.darwin.fonts
    self.modules.darwin.stylix
    {
      home-manager.users.${username}.imports = with hmModules; [
        carapace claude-code direnv ghostty git helix homelab
        jujutsu nushell opencode ssh starship television yazi zellij zoxide
      ];
    }
  ];
};

# hosts/taln/home.nix — slimmed down
{ pkgs, ... }: {
  imports = [ ../../home ];
  home.packages = with pkgs; [ nh bat fd fzf just tldr ... ];
  programs.ghostty.settings.window-decoration = "auto"; # per-host override example
}
```

## Specific Module Notes

- **zen-browser** — renamed from `browser.nix`. Google Chrome package removed; stays in `hosts/jezrien/home-packages.nix`.
- **pipewire** — keeps its `ryk.pipewire.*` options (rate, quantum, noiseSuppression) since they control non-trivial conditional logic. Moves to `modules/audio/`.
- **ssh** — self-imports `sops-nix` homeManager module. Accesses `hostname` and `username` via specialArgs.
- **helix** — uses `inputs.helix.packages` via the outer `{ inputs, ... }` function.
- **ghostty** — `hideWindowDecoration` and `usePredefinedSize` options are removed. The module sets sensible defaults; hosts override via `programs.ghostty.settings.window-decoration = "none"` and `programs.ghostty.settings.window-height = 50` directly.
- **starsector** — `mods.enable` option removed. Mods are always linked. If a host doesn't want mods, it simply doesn't import the module (or a future split into `starsector` + `starsector-mods` modules if needed).
- **git** — `gitconfig.enable` option removed. The HM-managed gitconfig (`home.file.".gitconfig"`) is always applied. Hosts that don't want it can override with `home.file.".gitconfig" = lib.mkForce {};`.
- **easyeffects, helix** — these modules use relative paths to config files (e.g., `../../configs/easyeffects/...`). Since they move from `legacy-modules/home-manager/` to `modules/<category>/`, all relative paths must be updated to point to the correct `configs/` location.

## What Gets Deleted

- `legacy-modules/home-manager/` — all 41 files + `default.nix`
- `legacy-modules/nixos/ssh.nix` — merged into `modules/misc/ssh.nix`
- `legacy-modules/nixos/gnome.nix` — merged into `modules/desktop/gnome.nix`
- `legacy-modules/darwin/aerospace.nix` — merged into `modules/desktop/aerospace.nix`
- All `ryk.<name>.enable` options for converted modules
- Bulk legacy imports from host configs
- All `ryk.*` enable references in roles for converted modules

## Out of Scope

- Legacy modules in `legacy-modules/desktop/` (hyprland, niri, etc.) — directory-based modules with their own `default.nix` + `home.nix` split. Future conversion pass.
- Legacy modules in `legacy-modules/gaming/` (audiorelay, jackify, nexus-mods) — same pattern, future pass.
- Legacy modules in `legacy-modules/misc/`, `legacy-modules/virtualization/`, `legacy-modules/shells/` — future pass.
- Non-home-manager legacy nixos modules (e.g., `legacy-modules/nixos/` beyond ssh/gnome) — future pass. Roles will still reference these via `ryk.*` until converted.
- `hosts/nixy/configuration.nix` imports `legacy-modules/nixos/ssh.nix` directly and sets `ryk.ssh.enable = true`. This must be updated to import `self.modules.nixos.ssh` instead, but nixy host conversion is otherwise out of scope.
