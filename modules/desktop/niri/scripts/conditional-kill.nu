#!/usr/bin/env nu

let protected_app_ids = ["steam_app_8500"]
let app_id = (niri msg --json focused-window | from json | get app_id)

let is_present = ($app_id in $protected_app_ids)

if $is_present {
  exit 0
} else {
  niri msg action close-window
}
