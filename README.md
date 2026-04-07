# Swoleflake

> [!WARNING]
> THIS IS A(LWAYS A) WORK IN PROGRESS!

A Nix flake managing NixOS and nix-darwin configurations for multiple machines, using home-manager as a module and sops-nix for secrets. Built on [flake-parts](https://github.com/hercules-ci/flake-parts). Tracks nixpkgs unstable.

## Hosts

| Host | Platform | Description |
|------|----------|-------------|
| `jezrien` | NixOS (x86_64-linux) | Primary desktop — Hyprland/niri, gaming, dev |
| `taln` | macOS (aarch64-darwin) | MacBook — Aerospace WM, dev |

## Build

```bash
# NixOS
sudo nixos-rebuild switch --flake .#jezrien

# macOS
darwin-rebuild switch --flake .#taln

# Dev shell
nix develop
```

## Architecture

Modules are auto-discovered via [import-tree](https://github.com/vic/import-tree) — drop a `.nix` file in `modules/` and it's loaded automatically.

```
modules/
  ai/           Claude Code, Codex, opencode, shared agent definitions, RTK
  audio/        PipeWire, EasyEffects
  base/         Fonts, Nix defaults, Stylix, meta-options
  browser/      Firefox, Zen Browser
  desktop/      Aerospace, Fuzzel, Walker, Flameshot, GNOME, KDE, Swaylock, ...
  dev/          Git, Helix, Neovim, Zed, Jujutsu, Yaak
  gaming/       Steam, Lutris, Star Citizen, EVE Online, VR, Starsector, ...
  groups/       Cross-platform feature sets (developer, gaming, 3d-printing)
  hosts/        Per-host wiring + system/hardware configs + secrets
  misc/         1Password, BTRFS, SSH, keyboards, OBS, Razer, Wooting
  nixos/        NixOS-specific base config
  shell/        Fish, Starship, Atuin, Carapace, Direnv, Zoxide
  social/       Discord
  terminal/     Ghostty, Kitty, WezTerm, tmux, Zellij, bat, btop, yazi, ...
  virtualization/ Docker, VFIO, virt-manager
configs/        Raw dotfiles (fish, neovim, starship, wezterm, ...) symlinked by HM
overlays/       Package additions and modifications
pkgs/           Custom derivations (eve-wrench, opentrack, rackpeek, ...)
shells/         Dev shell definitions
scripts/        Bootstrap scripts for LXC containers
```

### Module patterns

- Home-manager runs as a NixOS/Darwin module (not standalone)
- Groups (`modules/groups/`) compose modules into cross-platform feature sets
- Host configs live in `modules/hosts/<name>/` with `_`-prefixed files excluded from import-tree
- AI agent definitions are shared across tools via `modules/ai/_agents.nix`

### Secrets

SOPS with age encryption. Keys in `.sops.yaml`, per-host `secrets.yaml` files in `modules/hosts/<name>/`.

## TODO

- [ ] Remove passing username/hostname around — create option/config for it
