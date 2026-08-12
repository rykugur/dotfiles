#!/usr/bin/env nu

# workaround for an issue w/ Niri and EVE Online (perhaps others);
# taking EVE out of fullscreen messes up my overview/window
# placements, among other more minor issues

const blocked_app_ids = ["steam_app_8500"]
let focused = (niri msg --json focused-window | complete)

if $focused.exit_code != 0 {
  # nothing focused or other error, ignore and move along
  niri msg action fullscreen-window
  exit 0
}

let app_id = ($focused.stdout | from json | get app_id)
let is_present = ($app_id in $blocked_app_ids)

if $app_id == null {
  niri msg action fullscreen-window
} else if ($app_id in $blocked_app_ids) {
  # Do nothing - protect the fullscreen game
} else {
  # Normal case — toggle
  niri msg action fullscreen-window
}
