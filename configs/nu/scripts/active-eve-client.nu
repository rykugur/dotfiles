#!/usr/bin/env nu

let clients = (hyprctl clients -j | from json)
let eve_clients = ($clients | where title =~ '^EVE -')

if not ($eve_clients | is-empty) {
  let focused_eves = ($eve_clients | where focusHistoryID >= 0)
  if ($focused_eves | is-empty) {
    ($eve_clients | sort-by address | get 0.title)
  } else {
    ($focused_eves | sort-by focusHistoryID | get 0.title)
  }
}
