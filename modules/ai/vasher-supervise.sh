#!/usr/bin/env bash
set -u

if (( $# > 1 )) || (( $# == 1 )) && [[ $1 != --digest ]]; then
  printf 'usage: vasher-supervise [--digest]\n' >&2
  exit 2
fi
digest_run=false
(( $# == 1 )) && digest_run=true

base_url=${VASHER_SUPERVISE_URL:-http://vasher.local.ryk.sh:5080/api}
state_dir=${VASHER_SUPERVISE_STATE:-"$HOME/.local/state/vasher-supervise"}
state_file="$state_dir/last-seen.json"
digest_file="$state_dir/digest.md"
mkdir -p "$state_dir"

state='{"lastMonitorEventId":"","lastAgentEventId":"","incidentKey":"","unreachable":0}'
if [[ -s $state_file ]] && jq -e 'type == "object"' "$state_file" >/dev/null 2>&1; then
  state=$(jq -c '{lastMonitorEventId:(.lastMonitorEventId // ""),lastAgentEventId:(.lastAgentEventId // ""),incidentKey:(.incidentKey // ""),unreachable:(.unreachable // 0)}' "$state_file")
fi
write_state() {
  local value=$1 tmp
  tmp=$(mktemp "$state_dir/.last-seen.XXXXXX") || return
  printf '%s\n' "$value" > "$tmp"
  mv "$tmp" "$state_file"
}

fetch() { curl --fail --silent --show-error --max-time 10 "$1"; }
status=$(fetch "$base_url/status.json" 2>/dev/null) || status=
events=$(fetch "$base_url/events.json" 2>/dev/null) || events=
if [[ -z $status || -z $events ]] || ! jq -e 'type == "object"' <<<"$status" >/dev/null 2>&1 || ! jq -e 'type == "array"' <<<"$events" >/dev/null 2>&1; then
  unreachable=$(jq -r '.unreachable' <<<"$state")
  (( unreachable < 2 )) && unreachable=$((unreachable + 1))
  state=$(jq -c --argjson count "$unreachable" '.unreachable = $count' <<<"$state")
  write_state "$state"
  if (( unreachable == 2 )) && [[ $(jq -r '.unreachable' "$state_file") == 2 ]] && [[ ! -e "$state_dir/.unreachable-notified" ]]; then
    notify-send --urgency=critical 'Vasher is unreachable' 'Two consecutive supervisor polls failed.' || true
    : > "$state_dir/.unreachable-notified"
  fi
  exit 0
fi

rm -f "$state_dir/.unreachable-notified"
state=$(jq -c '.unreachable = 0' <<<"$state")
write_state "$state"

agent_events=$(fetch "$base_url/agent-events.json" 2>/dev/null) || agent_events='[]'
jq -e 'type == "array"' <<<"$agent_events" >/dev/null 2>&1 || agent_events='[]'
log=$(fetch "$base_url/log.txt" 2>/dev/null) || log=

monitor_id=$(jq -r '.[0].id // ""' <<<"$events")
agent_id=$(jq -r '.[0].id // ""' <<<"$agent_events")
last_monitor=$(jq -r '.lastMonitorEventId' <<<"$state")
last_agent=$(jq -r '.lastAgentEventId' <<<"$state")
status_state=$(jq -r '.state // "unknown"' <<<"$status")
revision=$(jq -r '.revision // .candidateRevision // ""' <<<"$status")
updated_at=$(jq -r '.updatedAt // ""' <<<"$status")
incident_key=
case "$status_state" in
  failed|stale|needs-attention|blocked) incident_key="$status_state:$revision:$updated_at" ;;
esac
old_incident=$(jq -r '.incidentKey' <<<"$state")

work=$digest_run
[[ -n $monitor_id && $monitor_id != "$last_monitor" ]] && work=true
[[ -n $agent_id && $agent_id != "$last_agent" ]] && work=true
[[ -n $incident_key && $incident_key != "$old_incident" ]] && work=true
$work || exit 0

merged=$(jq -cn --argjson monitor "$events" --argjson agent "$agent_events" '
  [($monitor[] | . + {source:(.source // "monitor")}), ($agent[] | . + {source:(.source // "agent")})]
  | sort_by(.timestamp // "") | reverse | .[:3]')
# Use the monitor's header/query patterns and cover common key-value secret fields.
redacted_log=$(printf '%s' "$log" | tail -n 200 | jq -Rs '
  gsub("(?im)(^authorization:\\s*(?:bearer|token)\\s+)\\S+"; "${1}[REDACTED]")
  | gsub("(?im)(^x-api-key:\\s*)\\S+"; "${1}[REDACTED]")
  | gsub("(?i)([?&](?:access_token|token|key|credential)=)[^&\\s]+"; "${1}[REDACTED]")
  | gsub("(?i)(\\b(?:secret|password|token|credential)\\s*[=:]\\s*)[^&\\s]+"; "${1}[REDACTED]")')
# Drop oldest characters until the JSON string's UTF-8 payload is within 32 KiB.
while (( $(jq -r 'utf8bytelength' <<<"$redacted_log") > 32768 )); do
  redacted_log=$(jq -c '.[1024:]' <<<"$redacted_log")
done

evidence=$(jq -cn --argjson status "$status" --argjson events "$merged" --arg log "$(jq -r . <<<"$redacted_log")" \
  '{status:$status,events:$events,log:$log,channel:"ssh -i ~/.ssh/vasher-agent vasher-agent@vasher.local.ryk.sh"}')
prompt=$(cat <<EOF
Use the vasher-supervisor skill to triage this Vasher evidence. Explain the incident briefly. If and only if an action is safe and its preconditions are evidenced, end with exactly one permitted action JSON object; otherwise state an explicit no-action decision. A channel rejection is terminal and must not be reshaped or retried.

$evidence
EOF
)

model_error=
if output=$(hermes --skills vasher-supervisor --oneshot "$prompt" 2>"$state_dir/.hermes-error"); then
  printf '%s\n' "$output" > "$digest_file"
else
  model_error=$(cat "$state_dir/.hermes-error")
  {
    printf '# Vasher raw evidence fallback\n\n'
    printf 'Inference error: %s\n\n```json\n%s\n```\n' "$model_error" "$evidence"
  } > "$digest_file"
fi
rm -f "$state_dir/.hermes-error"

next_state=$(jq -c --arg monitor "$monitor_id" --arg agent "$agent_id" --arg incident "$incident_key" \
  '.lastMonitorEventId=$monitor | .lastAgentEventId=$agent | .incidentKey=$incident' <<<"$state")
write_state "$next_state"

severity=$(jq -nr --arg state "$status_state" --argjson events "$merged" '
  if ($state == "failed" or $state == "needs-attention" or $state == "blocked") then "warning"
  elif any($events[]; ((.severity // "") == "critical" or (.severity // "") == "warning")) then "warning"
  else "informational" end')
if [[ $severity == warning ]]; then
  notify-send --urgency=critical 'Vasher needs attention' "State: $status_state. See $digest_file" || true
fi

[[ -n $model_error ]] && exit 0
proposal=$(printf '%s' "$output" | jq -c -e '
  if .verb == "retry-exact" then keys_unsorted == ["verb","revision"] and (.revision | test("^[0-9a-f]{40}$"))
  elif .verb == "narrow-inputs" then keys_unsorted == ["verb","base","inputs"] and (.base | test("^[0-9a-f]{40}$")) and (.inputs == ["nixpkgs"])
  elif .verb == "hold-input" then keys_unsorted == ["verb","input","revision","expires","reason"] and .input == "nixpkgs" and (.revision | test("^[0-9a-f]{40}$")) and (.expires | test("^[0-9]{4}-[0-9]{2}-[0-9]{2}$")) and (.reason | type == "string")
  elif .verb == "release-input" then keys_unsorted == ["verb","input"] and .input == "nixpkgs"
  else false end' 2>/dev/null) || exit 0
key="$HOME/.ssh/vasher-agent"
if [[ ! -f $key ]]; then
  printf '\nProposal retained: SSH key is missing at `%s`; no action was attempted.\n' "$key" >> "$digest_file"
  exit 0
fi
set +e
response=$(printf '%s\n' "$proposal" | ssh -i "$key" vasher-agent@vasher.local.ryk.sh)
ssh_status=$?
set -e
printf '\nChannel response (exit %s): `%s`\n' "$ssh_status" "$response" >> "$digest_file"
exit 0
