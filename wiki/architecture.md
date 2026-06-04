---
title: Architecture
category: core
date: 2026-06-03
tags: [architecture, dendritic, flake-parts, import-tree, modules, groups]
sources: ["CLAUDE.md", "flake.nix", "DENDRITIC_MIGRATION.md", "docs/superpowers/specs/2026-03-23-dendritic-module-conversion-design.md", "modules/hosts/jezrien/default.nix"]
related: ["overview.md", "modules.md", "hosts.md", "history.md"]
---

# Architecture

Swoleflake uses a **dendritic** (fine-grained, self-describing, auto-discovered) module system on top of flake-parts and `import-tree`. This is a deliberate evolution away from traditional explicit `imports = [ ./foo.nix ./bar.nix ... ]` lists.

## Loading pipeline (current)

1. `flake.nix` declares inputs (nixpkgs unstable, flake-parts, home-manager, nix-darwin, import-tree, sops-nix, stylix, many others including AI-specific flakes) and enables `flake-parts.flakeModules.modules`.
2. `outputs` calls `flake-parts.lib.mkFlake` and does:
   ```nix
   imports = [
     inputs.flake-parts.flakeModules.modules
     (inputs.import-tree ./modules)
   ];
   ```
3. `import-tree ./modules` recursively finds every `.nix` file under `modules/` (files/directories whose name starts with `_` are skipped by convention for "private" files).
4. Each discovered file is imported as a flake-parts top-level module. Inside the module the file typically does:
   ```nix
   { ... }:
   {
     flake.modules.nixos.my-feature = ./path-or-inline-module;
     # or for home-manager
     flake.modules.homeManager.my-feature = ...
   }
   ```
5. Host configuration modules (in `modules/hosts/<name>/default.nix`) then consume from the accumulated `config.flake.modules` (or `self.modules`) plus legacy paths, home-manager setup, specialArgs, and produce `flake.nixosConfigurations.<name>` / `darwinConfigurations`.

The net effect: dropping a new correctly-shaped `.nix` file into `modules/` (in the right category subdir) makes it available everywhere without touching central lists.

## Module loading order notes (from CLAUDE.md)

**NixOS hosts (jezrien)**:
`flake.nix` → `modules/base` + `modules/nixos` + feature modules from `modules/` + `groups/` + `hosts/<name>/`

**Darwin (taln)**:
`flake.nix` → `modules/darwin` + `modules/base` + `hosts/taln/configuration.nix`

(These orders are approximations; the actual composition happens inside the host modules.)

## Groups (the composition layer)

`modules/groups/` contains higher-level "feature set" modules (developer, gaming, printing3d / _3dp). These are imported into a user's home-manager config inside the host wiring. They pull in many individual modules, providing a single toggle point for "I want the full dev + gaming experience on this machine".

This replaced (or is replacing) an older `roles/` concept.

## Special args

All modules receive (via `extraSpecialArgs` or the module system):

- `inputs`
- `outputs` (the flake outputs / `self`)
- `hostname`
- `username`

This removes a lot of boilerplate passing of `username` and `hostname` everywhere (though some TODOs remain to fully eliminate manual passing).

## Home-manager integration

Home-manager is used **as a NixOS / nix-darwin module**, never standalone. Host configs set up `home-manager.users.<name>` and pass the collected `hmModules` (from `config.flake.modules.homeManager`).

`useGlobalPkgs = true` is standard.

## Secrets

`sops-nix` with age keys. `.sops.yaml` at repo root defines key groups. Each host has `modules/hosts/<name>/secrets.yaml` (encrypted). Modules declare `sops.secrets.foo = { sopsFile = ./secrets.yaml; ... }` in the home-manager part.

## Overlays & custom packages

- `overlays/default.nix` exports additions + modifications.
- `pkgs/default.nix` defines the actual derivations.
- Exposed both as `packages.<system>.<name>` (after filtering) and via overlay for use inside configs.

Cachix substituters are configured for hyprland, nix-gaming, nix-citizen, helix, pi, chaotic/nyx.

## Legacy / transition

A large body of work ("the dendritic migration") moved from a classic structure (legacy-modules + explicit imports + roles) to the current form. See [history.md](history.md) and the dated plans/specs under `docs/superpowers/`.

Some legacy desktop modules are still pulled in explicitly on jezrien during the final cleanup phases.

## Why this shape?

- Zero-maintenance module discovery (no more "I forgot to import the new thing").
- Self-documenting: the file's location and registration tell you its purpose.
- Easy to reason about cross-platform (a module can register under multiple classes or be generic).
- Plays extremely well with AI agents: the structure is regular, so agents can navigate and modify modules reliably.
- The AI modules (`modules/ai/`) are themselves dendritic and use the same patterns — very meta when the agents are editing the system that manages them.

## Open questions / TODOs (as of bootstrap)

- Fully remove manual `username` / `hostname` threading (see CLAUDE.md).
- Complete draining of `legacy-modules/`.
- Some module options still live in old shapes; full consistency pass ongoing.

See [modules.md](modules.md) for an inventory of what's actually there today.
