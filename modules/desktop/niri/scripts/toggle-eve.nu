#!/usr/bin/env nu

let windows = niri msg --json windows | from json

let eveWindows = $windows | where $it.title =~ "^EVE -.*$"
let eveWindowIds = $eveWindows | get id
let eveWindowNames = $eveWindows | get title

let activeWindow = niri msg --json focused-window | from json
let eveIsActive = $activeWindow.id in $eveWindowIds

if $eveIsActive {
  let nextEveWindow = $eveWindows | where $it.id != $activeWindow.id | first
  niri msg action focus-window --id $nextEveWindow.id
} else {
  # always prioritize primary character when EVE is not in focus
  let specialTitle = "EVE - Ryk"
  let specialWindow  = $eveWindows | where title == $specialTitle | first
  niri msg action focus-window --id $specialWindow.id
}
