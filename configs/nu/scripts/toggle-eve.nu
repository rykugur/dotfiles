#!/usr/bin/env nu

use std/log

# ASSUMPTIONS/GOTCHAS
# - EVE clients are on separate workspaces (hyprland doesn't handle toggling focus and fullscreen very well).
# - EVE clients are sorted by pid, toggle order will follow that.

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

def get_sorted_eve_clients [] {
  let eve_clients = (hyprctl clients -j | from json | where {|c| $c.title | str starts-with "EVE - "})
  $eve_clients | where focusHistoryID >= 0 | sort-by focusHistoryID
}

let eve_clients = get_sorted_eve_clients
if ($eve_clients | is-empty) {
  exit 0
}

let focused_window = (hyprctl activewindow -j | from json)
let len = ($eve_clients | length)
let current_idx = ($eve_clients | enumerate | where item.address == $focused_window.address | get -i 0.index)

if not ($focused_window.title | str starts-with "EVE - ") {
  # just focused the most recently / last focused
  toggle_eve_workspace $eve_clients.0.workspace
} else {
  # we're already focused on an eve client, go to the next one
  # we can just use index 1 since we always sort by focusHistoryID

  # special case - if the current focused client is on a special workspace,
  # we need to toggle it first
  if (is_special $focused_window.workspace) {
    toggle_special_workspace
  }

  toggle_eve_workspace $eve_clients.1.workspace
}
