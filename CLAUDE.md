# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

"Swoleflake" — a Nix flake managing NixOS and nix-darwin configurations for multiple machines, using home-manager as a module and sops-nix for secrets. Built on flake-parts. Tracks nixpkgs unstable.

## Build/Deploy Commands

```bash
# NixOS (jezrien, nixy)
sudo nixos-rebuild switch --flake .#jezrien
sudo nixos-rebuild switch --flake .#nixy

# macOS (taln)
darwin-rebuild switch --flake .#taln

# Enter dev shell
nix develop

# Check flake validity
nix flake check

# Update a single input
nix flake update <input-name>
```

## Architecture

**Module loading order** (for NixOS hosts like jezrien):
`flake.nix` → `modules/base` + `modules/nixos` + `modules/` (feature modules) + `roles/` + `hosts/<name>/`

**Module loading order** (for Darwin hosts like taln):
`flake.nix` → `modules/darwin` + `modules/base` + `hosts/taln/configuration.nix`

### Key directories

- **`hosts/`** — Per-host configs. Each host has `configuration.nix` (system) and `home.nix` (user env). Three hosts: `jezrien` (NixOS desktop, x86_64-linux), `taln` (macOS, aarch64-darwin), `nixy` (NixOS LXC test container).
- **`modules/`** — Reusable NixOS/home-manager modules organized by category: `base/`, `nixos/`, `darwin/`, `home-manager/`, `desktop/`, `dev/`, `gaming/`, `misc/`, `virtualization/`.
- **`roles/`** — Higher-level NixOS-only compositions that group modules into feature sets (desktop, dev, gaming, terminal, server, 3dp). Roles use `lib.mkEnableOption` patterns.
- **`configs/`** — Raw dotfiles (fish, nushell, neovim, starship, wezterm, etc.) symlinked into home via home-manager.
- **`pkgs/`** — Custom package derivations. Exposed through overlays.
- **`overlays/`** — Package additions and modifications applied via `nixpkgs.overlays`.
- **`shells/`** — Dev shell definitions (default, react, rust, sptarkov-server).
- **`home/`** — Base home-manager config (sops setup, overlays, XDG).
- **`scripts/bootstrap/`** — Shell scripts for bootstrapping LXC containers.

### Secrets

SOPS with age encryption. Keys defined in `.sops.yaml`. Each host has a `secrets.yaml` with encrypted values accessed via `config.sops.secrets`.

### Special args available in modules

All modules receive `inputs`, `outputs`, `hostname`, and `username` via `specialArgs`.

## Nix Conventions

- Modules use `lib.mkEnableOption` / `lib.mkIf config.<option>.enable` patterns for toggling features
- Home-manager is used as a NixOS/Darwin module (not standalone)
- Overlays are split into `additions` (new packages) and `modifications` (overrides)
- Cachix substituters configured for hyprland, nix-gaming, nix-citizen, helix
