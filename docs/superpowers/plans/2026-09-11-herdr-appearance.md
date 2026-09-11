# Herdr Appearance Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Show agent notifications inside Herdr and make agent states and pane identities visually distinct.

**Architecture:** Keep all appearance settings in the existing Home Manager module. Extend `programs.herdr.settings.ui` with Herdr-native toast, status indicator, and pane label values. Home Manager will serialize these values to `~/.config/herdr/config.toml`.

**Tech Stack:** Nix, Home Manager, Herdr

## Global Constraints

- Modify only `modules/ai/herdr.nix`.
- Keep the existing shell selection, pane borders, pane gaps, and key bindings unchanged.
- Do not modify the Oh My Pi integration or Herdr lifecycle behavior.
- Use explicit values for the toast delivery, delay, and position.
- Do not add fallback or compatibility settings.
- Do not run Home Manager activation, `nixos-rebuild switch`, or `herdr server reload-config`. The user owns deployment and live interaction checks.

---

### Task 1: Configure the Herdr appearance

**Files:**
- Modify: `modules/ai/herdr.nix:20-23`

**Interfaces:**
- Consumes: Home Manager's `programs.herdr.settings.ui` free-form settings and Herdr's documented UI configuration keys.
- Produces: Generated Herdr settings for in-window toasts, symbol status indicators, and automatic agent labels on pane borders.

- [ ] **Step 1: Add the appearance settings**

  Replace the current `ui` attribute set with this complete value:

  ```nix
  ui = {
    pane_borders = true;
    pane_gaps = true;
    show_agent_labels_on_pane_borders = true;
    status_indicators = "symbols";
    toast = {
      delivery = "herdr";
      delay_seconds = 1;
      herdr.position = "bottom-right";
    };
  };
  ```

- [ ] **Step 2: Evaluate the generated UI settings**

  Run:

  ```bash
  nix eval --json .#nixosConfigurations.jezrien.config.home-manager.users.dusty.programs.herdr.settings.ui
  ```

  Expected: evaluation exits with status 0 and prints this JSON value. Attribute order does not matter.

  ```json
  {"pane_borders":true,"pane_gaps":true,"show_agent_labels_on_pane_borders":true,"status_indicators":"symbols","toast":{"delay_seconds":1,"delivery":"herdr","herdr":{"position":"bottom-right"}}}
  ```

- [ ] **Step 3: Build the affected Home Manager activation package**

  Run:

  ```bash
  nix build .#nixosConfigurations.jezrien.config.home-manager.users.dusty.home.activationPackage
  ```

  Expected: the build exits with status 0.

- [ ] **Step 4: Commit the configuration change**

  ```bash
  git add modules/ai/herdr.nix
  git commit -m "feat(herdr): refine notification indicators"
  ```

- [ ] **Step 5: Hand off deployment and live checks**

  Do not activate or reload the configuration. After the user deploys it, open Herdr with two agent panes and move one agent into a background state.

  Expected behavior:

  - A popup appears at the bottom-right after one second.
  - The sidebar uses distinct glyphs for blocked, working, done, idle, and unknown states.
  - Each pane border shows its detected agent name.
  - A manual pane name set with `prefix+Shift+p` replaces the automatic agent label.
