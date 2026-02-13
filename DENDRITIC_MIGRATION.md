# Dendritic Flakes Migration Plan

Migrating Swoleflake from a traditional module import structure to the dendritic flake-parts pattern using `import-tree`.

## What is the dendritic pattern?

Every `.nix` file under `modules/` is a flake-parts top-level module, auto-imported via `import-tree`. Modules register themselves into the appropriate class (`nixos`, `darwin`, `homeManager`) using `flake.modules.<class>.<name>`, rather than being explicitly imported by path in `flake.nix` or host configs.

## Phases

### Phase 1: Tooling Setup (Complete)

Added the required tooling and scaffolding so that dendritic modules can be written in subsequent phases, without breaking the existing configuration.

- Added `import-tree` flake input
- Enabled `flake-parts.flakeModules.modules` (provides `flake.modules.<class>.<name>` option infrastructure)
- Renamed `modules/` to `legacy-modules/` to free the path for dendritic modules
- Updated all references in `flake.nix`, host configs (`jezrien`, `taln`, `nixy`)
- Created new `modules/` directory with a placeholder module to validate the `import-tree` pipeline
- Verified with `nix flake check`

### Phase 2: Migrate Modules

Convert legacy modules to dendritic modules one at a time:

1. Move a module from `legacy-modules/` into `modules/`
2. Rewrite it as a flake-parts top-level module that registers into the appropriate class via `flake.modules.<class>.<name>`
3. Remove the explicit import from host configs / `flake.nix`
4. Verify with `nix flake check` and a test build

Repeat until `legacy-modules/` is empty, then remove it.

### Phase 3: Migrate Roles

Once modules are dendritic, roles can be reworked or eliminated — modules can compose themselves without a separate role layer.

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

# After Phase 1 (current)
legacy-modules/    # existing modules, unchanged
modules/           # dendritic modules, auto-imported by import-tree
  placeholder.nix

# After Phase 2 (goal)
modules/           # all modules, dendritic
  <module>.nix     # each file is a flake-parts top-level module
```

## Key Concepts

- `import-tree ./modules` — recursively discovers and imports all `.nix` files under `modules/` as flake-parts modules. Paths containing `/_` are ignored.
- `flake.modules.<class>.<name>` — registers a module into a class (`nixos`, `darwin`, `homeManager`, `generic`). Automatically wraps the module with `_class` metadata for type safety.
- Each dendritic module is self-contained: it declares its own options and registers itself into the right class. No central import list to maintain.
