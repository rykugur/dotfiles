# Herdr Pane Navigation Design

**Date:** 2026-08-09

## Goal

Preserve lowercase prefix tab navigation while adding Vim-directional split-pane focus bindings.

## Scope

Change only `modules/ai/herdr.nix`. No Oh My Pi package or integration behavior changes.

## Binding design

Herdr's tab API offers ordered navigation only, not directional movement. Therefore:

| Binding | Action |
|---|---|
| `prefix+h` | Select previous tab |
| `prefix+l` | Select next tab |
| `prefix+Shift+h` | Focus pane left |
| `prefix+Shift+j` | Focus pane down |
| `prefix+Shift+k` | Focus pane up |
| `prefix+Shift+l` | Focus pane right |

`prefix+Tab` and `prefix+Shift+Tab` retain Herdr's default pane-cycle bindings. No direct `Ctrl+h/j/k/l` bindings are added, preventing collisions with terminal applications and the existing Neovim/Zellij navigation model.

## Implementation

Populate `focus_pane_left`, `focus_pane_down`, `focus_pane_up`, and `focus_pane_right` in `programs.herdr.settings.keys`. Keep the existing `previous_tab` and `next_tab` values unchanged.

Home Manager renders the updated settings into `~/.config/herdr/config.toml` when the user deploys the configuration. This change does not modify OMP's lifecycle integration.

## Validation

1. Evaluate and build the affected Home Manager activation package; agents MUST NOT activate or deploy it.
2. The user may inspect the generated `[keys]` section after their normal deployment workflow.
3. The user may reload Herdr and verify `prefix+Shift+h/j/k/l` focuses the corresponding adjacent pane while `prefix+h/l` still selects the previous/next tab.

## Error handling

Herdr rejects malformed key strings during configuration load. The selected key syntax follows Herdr's documented `prefix+shift+<key>` grammar; no runtime fallback or compatibility alias is needed.
