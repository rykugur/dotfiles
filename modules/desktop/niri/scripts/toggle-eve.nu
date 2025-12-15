#!/usr/bin/env nu

def focusWindow [id: number] {
  niri msg action focus-window --id $id
}

let windows = niri msg --json windows | from json

let eveWindows = $windows | where $it.title =~ "^EVE -.*$"
let eveWindowIds = $eveWindows | get id
let eveWindowNames = $eveWindows | get title

let activeWindow = niri msg --json focused-window | from json
let eveIsActive = $activeWindow.id in $eveWindowIds

if $eveIsActive {
  let nextEveWindow = $eveWindows | where $it.id != $activeWindow.id | first
  focusWindow $nextEveWindow.id
} else {
  # always prioritize primary character when EVE is not in focus
  let specialTitle = "EVE - Ryk"
  let specialWindow  = $eveWindows | where title == $specialTitle

  if ($specialWindow | is-not-empty) {
    focusWindow ($specialWindow | first).id
  } else {
    focusWindow ($eveWindowIds | first)
  }
}
