#!/usr/bin/env nu

let clients = (hyprctl clients -j | from json)
let eve_clients = ($clients | where {|c| $c.title | str starts-with "EVE - "} | sort-by pid)

if ($eve_clients | is-empty) {
  exit 0
}

let eve_ws = ($eve_clients | get 0.workspace.id)
let current_ws = (hyprctl activeworkspace -j | from json | get id)

if $current_ws != $eve_ws {
  hyprctl dispatch workspace $eve_ws
} else {
  hyprctl cyclenext
  # let active_window = (hyprctl activewindow -j | from json)
  # let active_addr = $active_window.address

  # let addresses = ($eve_clients | get address)
  # let len = ($addresses | length)

  # let current_idx = ($addresses | enumerate | where item == $active_addr | get -i 0.index)
  # let next_idx = ($current_idx + 1) mod $len

  # let next_addr = ($addresses | get $next_idx)

  # if $next_addr != $active_addr {
  #   hyprctl dispatch focuswindow $"address:($next_addr)"
  #   sleep 100ms
  #   hyprctl dispatch fullscreenstate 2 0
  # }
}
