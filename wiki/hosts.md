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
  - Login shell is option-driven via `ryk.defaultShell` (default `nushell`; see [Modules → Default shell](modules.md))
  - Legacy desktop modules still partially active (dankMaterialShell, hyprland/niri configs in legacy)
- **Secrets**: `modules/hosts/jezrien/secrets.yaml`
- **Hardware config**: `_hardware-configuration.nix`
- **Special WM configs**: `_hyprland-config.nix`, `_niri-config.nix`
- **Networking**: single plain **dhcpcd** scripted-networking stack (`networking.useDHCP` in `_hardware-configuration.nix`); no NetworkManager/networkd. RTL8125 2.5GbE NIC uses the vendor `r8125` driver (`r8169` blacklisted in `_configuration.nix`).

Jezrien is the "full fat" machine where most new modules are proven.

> **Note on the `r8125` driver + slow Steam downloads.** The `r8125` swap in `_configuration.nix` was made chasing slow Steam downloads, but a 2026-07-09 investigation proved it is **not** the fix: the host (network, driver, DNS, disk) is all provably fast, and the slowness is a **Valve Steam-for-Linux client bug** (kernel-confirmed `app_limited` / ~177 KB receive window; upstream #13024). Keep the driver (a valid offload improvement) but don't attribute the Steam issue to it, and **don't build a CDN-blackhole module** — see [Steam-for-Linux Slow Download Investigation](sources/steam-linux-slow-download-investigation.md).

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
- **NFS**: mounts the shared storage on demand through the Darwin NFS automount module (macOS autofs; see [Modules → NFS automount](modules.md#nfs-automount)).

Taln demonstrates that the dendritic + groups approach gives near-identical experiences across OSes.

## vasher (LAN binary cache)

- **Platform**: `x86_64-linux`, NixOS, initially an LXC
- **Purpose**: prebuild Jezrien's current `master` closure and a nightly candidate that updates both flake inputs and OMP; serve retained signed paths through a LAN-only cache endpoint.
- **Status**: [Vasher work ledger](entities/vasher.md#status-dashboard) is a LAN-only Catppuccin Mocha dashboard that polls curated prebuild state, bounded history, and a 200-line log tail every five seconds.
- **Not a remote builder**: Jezrien only substitutes cache paths; it never delegates builds over SSH.
- **Promotion**: on a clean `master` checkout, run `scripts/vasher-promote.sh`. It fast-forwards only to `origin/cache-bump`, pushes `master`, then runs the local NixOS switch.
- **OMP updates**: only the nightly candidate runs `update-omp.sh`. A successful reduced-closure build publishes its tested `flake.lock` and `modules/ai/oh-my-pi/release.json` together on `cache-bump`; the normal promotion script advances both.
- **Retention**: five successful closures are retained as Nix GC roots.
- **Resources**: the LXC runs one derivation at a time with a fixed CPU and memory envelope.
- **Deploy**: use the normal NixOS rebuild for the published flake's `vasher` host; activation does not start a candidate.
- **Run/recover**: start a detached candidate with `systemctl start --no-block vasher-prebuild-candidate.service`; stop it through the container manager if resource pressure threatens the host.
Vasher prebuilds `nixosConfigurations.jezrien-prebuild`, which intentionally omits `bambu-studio`; Jezrien builds that package locally when promoting `cache-bump`.
- **Migration**: retain the role module and replace the LXC platform module with bare-metal hardware, filesystem, bootloader, and networking configuration.
- **Details**: [Vasher](entities/vasher.md) documents the candidate lifecycle, promotion boundary, dashboard, and operational checks.

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
