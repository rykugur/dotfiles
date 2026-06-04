---
title: Hosts
category: core
date: 2026-06-03
tags: [hosts, jezrien, taln, nixy]
sources: ["modules/hosts/jezrien/default.nix", "modules/hosts/taln/default.nix", "CLAUDE.md", "README.md"]
related: ["overview.md", "architecture.md"]
---

# Hosts

The three (sometimes four) machines managed by Swoleflake.

## jezrien (primary)

- **Platform**: x86_64-linux, NixOS
- **Form factor**: Desktop
- **Window managers**: Hyprland (primary) + niri (alternative)
- **Workload**: Heavy dev + gaming (Star Citizen via starcitizen-lite, EVE Online, Steam, Lutris, VR, Starsector, etc.)
- **Notable modules**:
  - Full AI agent suite (claude-code, codex, opencode, pi, ...)
  - Audio (easyeffects, pipewire)
  - Peripherals (razer, wooting, zsa)
  - Virtualization (docker, winboat, vfio?)
  - 1password, sops, btrfs maintenance, obs-studio, gamemode, appimage
  - Legacy desktop modules still partially active (dankMaterialShell, hyprland/niri configs in legacy)
- **Secrets**: `modules/hosts/jezrien/secrets.yaml`
- **Hardware config**: `_hardware-configuration.nix`
- **Special WM configs**: `_hyprland-config.nix`, `_niri-config.nix`

Jezrien is the "full fat" machine where most new modules are proven.

## taln (laptop)

- **Platform**: aarch64-darwin, nix-darwin + home-manager
- **Form factor**: MacBook (Apple Silicon)
- **Window manager**: Aerospace
- **Workload**: Portable dev + lighter gaming + travel
- **AI agents**: Full parity with jezrien (same modules/ai wiring)
- **Differences from jezrien**:
  - Uses darwin-specific modules
  - No heavy Linux gaming stack or VFIO
  - Different terminal / browser preferences sometimes
- **Secrets**: `modules/hosts/taln/secrets.yaml`

Taln demonstrates that the dendritic + groups approach gives near-identical experiences across OSes.

## nixy (test container)

- **Platform**: x86_64-linux, NixOS (LXC / container)
- **Purpose**: Fast iteration and validation of modules without risking the desktop
- **Minimal config**: Usually only base + whatever is being tested
- **Build command**: `sudo nixos-rebuild switch --flake .#nixy`

nixy appears in CLAUDE.md but is less prominent in current host modules (may live in older wiring or be ad-hoc).

## Common wiring pattern

Each host `modules/hosts/<name>/default.nix` (or `_configuration.nix` + `default.nix`):

- Declares the `flake.nixosConfigurations.<name>` (or darwin equivalent) using `nixpkgs.lib.nixosSystem` / darwin equivalent.
- Pulls in legacy desktop modules where still needed.
- Pulls base nixos/darwin modules.
- Sets up home-manager with `extraSpecialArgs` containing `hostname`, `username`, `inputs`, `outputs`.
- Imports the desired groups + individual home modules.
- Wires per-host sops secrets.
- Adds host-specific packages.

During the dendritic transition, hosts were the main place that still had explicit lists; the goal is to push as much composition as possible into groups and the modules themselves.

## Adding a new host (high level)

1. Create `modules/hosts/newhost/`
2. Add `_configuration.nix` (or equivalent) + `default.nix` that produces the configuration attr.
3. Add the machine to `systems` in flake.nix if new arch.
4. Create secrets if needed.
5. Wire into your deployment script / justfile / manual command.
6. (Future) a group or meta module may declare "this host exists".

See history of hosts consolidation in the superpowers specs.
