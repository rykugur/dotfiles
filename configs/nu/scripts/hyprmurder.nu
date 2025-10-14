#!/usr/bin/env nu

use std/log

log debug "hyprmurder!"

if (which zenity | is-empty) {
  log error "Zenity not installed, exiting."
  return
}

let selection = (hyprprop | from json)
log debug $"selection=($selection)"

let questionText = $"Do you want to murder pid=($selection.pid) class=($selection.class) title=($selection.title)?"
let questionTitle = $"Murder ($selection.title)?"

if ($selection | is-empty) {
  log error "Nothing selected, exiting."
  return
}

let answer = (zenity --question --text=$"($questionText)" --title=$"($questionTitle)" | complete)

if ($answer.exit_code == 0) {
  log debug $"Killing pid=($selection.pid)"
  kill -9 $selection.pid
} else {
  log debug "User chose no or canceled prompt, doing nothing."
}

log debug "Done."
