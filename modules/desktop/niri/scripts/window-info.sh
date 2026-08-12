#!/usr/bin/env bash
set -euo pipefail

picked=$(niri msg --json pick-window) || exit 0

title=$(jq -r '.title // ""' <<<"$picked")
app_id=$(jq -r '.app_id // ""' <<<"$picked")
pid=$(jq -r '.pid // ""' <<<"$picked")
proc_name="?"
[[ -n "$pid" && -r "/proc/$pid/comm" ]] && proc_name=$(< "/proc/$pid/comm")

printf 'Title:    %s\nApp ID:   %s\nPID:      %s\nProcess:  %s\n' \
  "$title" "$app_id" "$pid" "$proc_name" \
  | yad --text-info --title="Window Info" --width=600 --height=200 --button=Close:0
