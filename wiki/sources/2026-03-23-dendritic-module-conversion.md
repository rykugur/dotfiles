---
title: "2026-03-23 Dendritic Module Conversion (Design)"
category: source
date: 2026-06-03
tags: [dendritic, migration, design, home-manager, flake-parts]
sources: ["docs/superpowers/specs/2026-03-23-dendritic-module-conversion-design.md", "DENDRITIC_MIGRATION.md"]
related: ["history.md", "architecture.md", "modules.md"]
---

# Source Summary: Dendritic Module Conversion Design (2026-03-23)

Primary design artifact that defined the shape of the current `modules/` system.

## What it was solving

The repo had ~41 legacy home-manager modules under `legacy-modules/home-manager/` using the old pattern:

- `options.ryk.<name>.enable`
- `config = lib.mkIf config.ryk.<name>.enable { ... }`
- Central role files that listed everything
- Explicit imports in host configs and flake.nix

This created maintenance burden and didn't scale with AI-assisted development.

## The dendritic target shape

Each module becomes a thin flake-parts registrar:

```nix
{ inputs, ... }:
{
  flake.modules.homeManager.<name> = { config, lib, pkgs, ... }: {
    # the actual config, using upstream options directly
    programs.foo.enable = true;
    # or imports of other flakes' modules
  };
}
```

**Key decisions codified here**:

- **No per-module `enable` options** in the ryk namespace for the converted modules. Import = on.
- **No custom `ryk.*` namespace** for most user modules. Use the programs/home.* options the upstream modules already expose.
- **Cross-class in one file** when a feature has both system and home parts (e.g. ssh, gnome).
- **Self-contained external deps**: the module file itself does `imports = [ inputs.zen-browser.homeModules.default ];` etc.
- **Auto-discovery via import-tree** — the act of placing the file under `modules/<category>/` is the registration. No lists.

## Category reorganization

Old split by "nixos vs home-manager" became domain categories:

- `terminal/`, `shell/`, `dev/`, `desktop/`, `browser/`, `audio/`, `gaming/`, `social/`, `misc/`, `productivity/`, `virtualization/`, `ai/`, `nixos/`, `base/`, `groups/`, `hosts/`

Some modules moved categories (pipewire from nixos/ to audio/).

## Role / group impact

The design still assumed roles would exist for a while. Roles would change from listing `ryk.foo.enable = true` to doing:

```nix
imports = with config.flake.modules.homeManager; [ ghostty bat helix ... ];
```

Later work (roles-to-groups plan) moved even further away from roles.

## Host changes

Hosts stop bulk-importing legacy and instead pick from `self.modules.*` + groups.

## Lasting influence

This spec set the **"no enable options, import = activation, auto-discovered, domain categories, self-contained"** philosophy that is now visible in the current `modules/` tree and described in [architecture.md](../architecture.md) and [modules.md](../modules.md).

Many of the concrete file moves and renames happened according to the table in this document.

## How it was executed

See the companion plan `2026-03-23-dendritic-module-conversion.md` (task checklist) and later migration plans for the actual ordered edits, verification commands (`nix flake check` after each tranche), and the phased approach.

The wiki's [history.md](../history.md) summarizes the campaign at a higher level.

## Artifacts produced

- The current `modules/` tree layout
- The `import-tree` line in `flake.nix`
- The `flake.modules.<class>.<name>` registration pattern used everywhere
- The groups/ direction (further refined later)
- This very wiki now exists in part because the structure became regular enough for reliable LLM navigation and maintenance.

---

*Ingested during initial wiki bootstrap, 2026-06-03. Source file remains the authoritative design record.*
