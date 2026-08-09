# Herdr Pane Navigation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add prefix-plus-shift Vim-directional pane focus bindings without changing existing prefix tab navigation.

**Architecture:** Keep all Herdr settings in the existing Home Manager module. Extend its `programs.herdr.settings.keys` attribute set with Herdr-native pane-focus actions; leave OMP integration and tab actions untouched. Home Manager serializes the settings to `~/.config/herdr/config.toml`.

**Tech Stack:** Nix, Home Manager, Herdr

## Global Constraints

- Modify only `modules/ai/herdr.nix`; do not change `modules/ai/oh-my-pi/default.nix` or OMP integration behavior.
- Preserve `previous_tab = "prefix+h"` and `next_tab = "prefix+l"` exactly.
- Use Herdr's documented key syntax with lowercase `shift`: `prefix+shift+h/j/k/l`.
- Do not add direct `Ctrl+h/j/k/l` bindings or compatibility aliases.
- Agents MUST NOT run `nixos-rebuild switch`, Home Manager activation, `herdr server reload-config`, or any other deployment command; deployment and live interaction verification are user-owned.

---

### Task 1: Configure directional pane focus

**Files:**
- Modify: `modules/ai/herdr.nix:24-30`

**Interfaces:**
- Consumes: Home Manager's `programs.herdr.settings.keys` option and Herdr's native `focus_pane_left`, `focus_pane_down`, `focus_pane_up`, and `focus_pane_right` keys.
- Produces: Generated Herdr TOML bindings: `prefix+shift+h/j/k/l` for left/down/up/right pane focus.

- [ ] **Step 1: Add the four focus bindings to the existing `keys` attribute set**

  Replace the two empty focus bindings and add the two missing directional bindings, while preserving the tab bindings:

  ```nix
  keys = {
    previous_tab = "prefix+h";
    next_tab = "prefix+l";
    focus_pane_left = "prefix+shift+h";
    focus_pane_down = "prefix+shift+j";
    focus_pane_up = "prefix+shift+k";
    focus_pane_right = "prefix+shift+l";
  };
  ```

- [ ] **Step 2: Evaluate the affected Home Manager activation package**

  Run:

  ```bash
  nix eval .#nixosConfigurations.jezrien.config.home-manager.users.dusty.home.activationPackage.drvPath
  ```

  Expected: evaluation exits with status 0 and prints a `/nix/store/...-home-manager-generation.drv` path.

- [ ] **Step 3: Build the affected Home Manager activation package**

  Run:

  ```bash
  nix build .#nixosConfigurations.jezrien.config.home-manager.users.dusty.home.activationPackage
  ```

  Expected: build exits with status 0.

- [ ] **Step 4: Hand off deployment and live verification to the user**

  Do not activate or reload the configuration. After the user deploys it through their normal workflow, they can inspect the generated `[keys]` section, reload Herdr, and exercise a two-by-two pane layout: `prefix+Shift+h`, `prefix+Shift+j`, `prefix+Shift+k`, and `prefix+Shift+l` should focus the corresponding adjacent panes; `prefix+h` and `prefix+l` should still select the previous and next tabs.

- [ ] **Step 5: Commit the configuration change**

  ```bash
  git add modules/ai/herdr.nix
  git commit -m "feat(herdr): add directional pane navigation"
  ```
