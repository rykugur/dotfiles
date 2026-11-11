#!/usr/bin/env nu

# Capture the target before the confirmation dialog takes focus.
let focused = niri msg --json focused-window | from json
if $focused == null {
  exit 0
}

let answer = (
  yad
    --title="Confirm Close"
    --text=$"Close this window?\n\n($focused.title)"
    --no-markup
    --image=dialog-question
    --button=Yes:0
    --button=No:1
    --response=0
    --fixed
    --center
  | complete
)

if $answer.exit_code == 0 {
  niri msg action close-window --id $focused.id
}
