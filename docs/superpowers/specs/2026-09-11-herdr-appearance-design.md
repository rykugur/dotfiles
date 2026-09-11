# Herdr Appearance Design

Date: 2026-09-11

## Goal

Show agent notifications inside the Herdr window. Use distinct symbols for each agent state. Show detected agent names on pane borders.

## Scope

Change only `modules/ai/herdr.nix`. Keep the existing shell selection, pane borders, pane gaps, and key bindings.

Home Manager continues to write `~/.config/herdr/config.toml`. This change does not modify the Oh My Pi integration or Herdr lifecycle behavior.

## Notification design

Set `ui.toast.delivery` to `"herdr"`. Herdr will show agent state notifications as popups inside its window.

Set `ui.toast.delay_seconds` to `1`. Set `ui.toast.herdr.position` to `"bottom-right"`. These explicit values keep the selected behavior if upstream defaults change.

## Status indicator design

Set `ui.status_indicators` to `"symbols"`. Herdr will use different static glyphs for blocked, working, done, idle, and unknown states.

The glyph shape makes each state distinct. Color remains an additional signal rather than the only signal.

## Pane label design

Set `ui.show_agent_labels_on_pane_borders` to `true`. Herdr will show a detected or reported agent name in a split pane border.

A manual pane name takes priority over the automatic agent label. The existing `prefix+Shift+p` binding opens the pane rename action.

## Error handling

Herdr validates the delivery mode, position, and indicator mode when it loads the configuration. No fallback or compatibility setting is necessary.

## Verification

Evaluate the Home Manager module and inspect the generated settings. Make sure that the result contains the selected notification, indicator, and pane label values.

After deployment, open Herdr with two agent panes. Move one agent to a background state and make sure that a popup appears at the bottom-right after one second.

Make sure that the sidebar uses distinct state glyphs. Make sure that pane borders show automatic agent labels and that a manual pane name replaces its automatic label.
