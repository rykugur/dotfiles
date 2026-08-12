# Dendritic Flakes Migration Plan

Migrating Swoleflake from a traditional module import structure to the dendritic flake-parts pattern using `import-tree`.

## What is the dendritic pattern?

Every `.nix` file under `modules/` is a flake-parts top-level module, auto-imported via `import-tree`. Modules register themselves into the appropriate class (`nixos`, `darwin`, `homeManager`) using `flake.modules.<class>.<name>`, rather than being explicitly imported by path in `flake.nix` or host configs.

## Status

The migration is complete as of 2026-08-12.

### Phase 1: Tooling setup (complete)

- Added the `import-tree` flake input.
- Enabled `flake-parts.flakeModules.modules`.
- Renamed the original `modules/` tree to `legacy-modules/` while conversion was in progress.
- Validated the discovery pipeline with `nix flake check`.

### Phase 2: Module migration (complete)

Every reusable module now registers through `flake.modules.<class>.<name>` under
`modules/`. The last holdouts—hyprland, niri, DankMaterialShell, and noctalia—
were converted into cross-class desktop modules. `legacy-modules/` was removed.

The desktop conversion also:

- kept `ryk.hyprland.*` and `ryk.niri.*` as host configuration values;
- made bars compositor-aware through `ryk.desktop.compositor`;
- removed the unavailable hyprland scrolling plugin path;
- ported noctalia from the removed v4 `programs.noctalia-shell` interface to the
  v5 `programs.noctalia` TOML schema and `noctalia msg` IPC;
- removed the unused legacy desktop keybind helper.

### Phase 3: Roles migration (complete)

The old role layer was replaced by composable modules and `modules/groups/`.

## Directory Structure

```
# Before
modules/           # all modules, explicitly imported by path
  base/
  nixos/
  darwin/
  home-manager/
  desktop/
  ...

# Current
modules/           # all modules, dendritic and auto-imported
  <category>/
    <module>.nix   # registers one or more module classes
```

## Key Concepts

- `import-tree ./modules` — recursively discovers and imports all `.nix` files under `modules/` as flake-parts modules. Paths containing `/_` are ignored.
- `flake.modules.<class>.<name>` — registers a module into a class (`nixos`, `darwin`, `homeManager`, `generic`). Automatically wraps the module with `_class` metadata for type safety.
- Each dendritic module is self-contained: it declares its own options and registers itself into the right class. No central import list to maintain.
