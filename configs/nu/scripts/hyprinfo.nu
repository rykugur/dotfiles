#!/usr/bin/env nu

use std/log

log debug "hyprinfo!"

if (which zenity | is-empty) {
  log error "Zenity not installed, exiting."
  return
}

let selection = (hyprprop | from json)
log debug $"selection=($selection)"

let infoTitle = "Hyprinfo"
let infoText = $"
initialClass=($selection.initialClass)
class=($selection.class)
initialTitle=($selection.initialTitle)
title=($selection.title)
"

zenity --info --text=$"($infoText)" --title=$"($infoTitle)"
