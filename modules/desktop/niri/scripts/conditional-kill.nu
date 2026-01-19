#!/usr/bin/env nu

# script that will only call close-window if the focused app
# is not a protected app.
# This exists so I don't accidentally close a game window.

# TODO: add Star Citizen
const protected_app_ids = ["steam_app_8500"]
let focused = (niri msg --json focused-window | complete)

if $focused.exit_code != 0 {
  # nothing focused or other error, ignore and move along
  niri msg action close-window
  exit 0
}

let app_id = ($focused.stdout | from json | get app_id)
let is_present = ($app_id in $protected_app_ids)

if $is_present {
  exit 0
} else {
  niri msg action close-window
}
