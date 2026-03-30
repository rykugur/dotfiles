# Espanso Snippets Module Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create a home-manager module for Espanso text snippet expansion with a `:install-helix` snippet.

**Architecture:** A single Nix module that enables `services.espanso` and configures default matches. Snippets are defined as Nix attrs and rendered to YAML via the home-manager module.

**Tech Stack:** Nix, home-manager, Espanso

---

## Task 1: Create Espanso Module

**Files:**
- Create: `modules/terminal/espanso.nix`

- [ ] **Step 1: Write the espanso module**

```nix
{ lib, config, ... }:

let
  inherit (lib) types mkEnableOption mkOption mkIf;
in
{
  options.espanso = {
    snippets = mkOption {
      type = types.listOf types.attrs;
      default = [ ];
      description = "List of Espanso snippet definitions";
    };
  };

  config = mkIf config.services.espanso.enable {
    services.espanso.configs.default = {
      matches = config.espanso.snippets;
    };
  };
}
```

- [ ] **Step 2: Commit**

```bash
git add modules/terminal/espanso.nix
git commit -m "feat(espanso): add terminal/espanso module"
```

---

## Task 2: Wire the Module into the Flake

**Files:**
- Modify: `flake.nix`

- [ ] **Step 1: Add module export**

The flake uses flake-parts with `inputs.import-tree ./modules`. The espanso module will be auto-imported from `modules/terminal/`. No flake.nix changes needed.

- [ ] **Step 2: Verify flake structure**

Run: `nix flake check --no-build`
Expected: Valid flake

- [ ] **Step 3: Commit (if changed)**

```bash
git add flake.nix
git commit -m "chore(espanso): no-op verify flake"
```

---

## Task 3: Add `:install-helix` Snippet to a Host

**Files:**
- Modify: `modules/hosts/<host>/home.nix` (choose one host, e.g., jezrien)

- [ ] **Step 1: Read existing host home config**

Read `modules/hosts/jezrien/` or check for home.nix

- [ ] **Step 2: Add espanso import and snippet**

```nix
imports = [
  # ... existing imports ...
  self.modules.homeManager.espanso
];

services.espanso.enable = true;

espanso.snippets = [
  {
    trigger = ":install-helix";
    replace = "curl -fsSL sh.ryk.sh/install-helix-deb | bash -s --";
  }
];
```

- [ ] **Step 3: Commit**

```bash
git add modules/hosts/jezrien/home.nix
git commit -m "feat(espanso): add :install-helix snippet to jezrien"
```

---

## Task 4: Verify Configuration Evaluates

**Files:** None (validation only)

- [ ] **Step 1: Evaluate the host configuration**

Run: `nix eval .#nixosConfigurations.jezrien.config.espanso.snippets --json`
Expected: JSON array with the `:install-helix` snippet

- [ ] **Step 2: Verify services.espanso config**

Run: `nix eval .#nixosConfigurations.jezrien.config.services.espanso.configs --json`
Expected: Shows the matches array

---

## Self-Review Checklist

- [ ] All snippets from spec are in the module
- [ ] Module follows home-manager module conventions
- [ ] Nix code uses `lib/` helpers (mkIf, mkOption, types)
- [ ] Imports are correct in host config
- [ ] No placeholder/TODO in code
