#!/usr/bin/env nu

use std/log

# ASSUMPTIONS/GOTCHAS
# - EVE clients are on separate workspaces (hyprland doesn't handle toggling focus and fullscreen very well).
# - EVE clients are sorted by pid, toggle order will follow that.

# TODO: special workspace handling will fail with speical workspaces not named "special"
# TODO: can we make focus changes not change fullscreenstate?
 
def is_special [workspace] {
  return ($workspace.name =~ special)
}

def toggle_special_workspace [] {
  log debug "Toggling special workspace"
  hyprctl dispatch togglespecialworkspace
}

def toggle_workspace [workspace] {
  log debug $"Toggling workspace.id=($workspace.id)"
  hyprctl dispatch workspace $workspace.id
}

def toggle_eve_workspace [workspace] {
  if (is_special $workspace) {
    toggle_special_workspace
  } else {
    toggle_workspace $workspace
  }
}

let eve_clients = (hyprctl clients -j | from json | where {|c| $c.title | str starts-with "EVE - "} | sort-by pid)
if ($eve_clients | is-empty) {
  exit 0
}

let focused_window = (hyprctl activewindow -j | from json)
if not ($focused_window.title | str starts-with "EVE - ") {
  # just focus the first eve client
  toggle_workspace ($eve_clients | first | get workspace)
} else {
  # we're focusing an eve client, switch to the next one
  let len = ($eve_clients | length)
  let current_idx = ($eve_clients | enumerate | where item.address == $focused_window.address | get -i 0.index)
  let current_client = ($eve_clients | get $current_idx)
  let next_idx = ($current_idx + 1) mod $len
  let next_client = ($eve_clients | get $next_idx)

  # special case - if the current focused client is on a special workspace,
  # we need to toggle it first
  if (is_special $current_client.workspace) {
    toggle_special_workspace
  }
  toggle_eve_workspace $next_client.workspace
}
