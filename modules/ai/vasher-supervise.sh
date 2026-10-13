#!/usr/bin/env bash
set -Eeuo pipefail

if (( $# > 1 )) || (( $# == 1 )) && [[ $1 != --digest ]]; then
  printf 'usage: vasher-supervise [--digest]\n' >&2
  exit 2
fi
digest_run=false
if (( $# == 1 )); then
  digest_run=true
fi

# The weekly digest owns Monday's 09:00 local-time slot.
now=${VASHER_SUPERVISE_NOW:-$(date '+%u %H:%M')}
if ! $digest_run && [[ $now == '1 09:00' ]]; then
  exit 0
fi

base_url=${VASHER_SUPERVISE_URL:-http://vasher.local.ryk.sh:5080/api}
state_dir=${VASHER_SUPERVISE_STATE:-"$HOME/.local/state/vasher-supervise"}
state_file="$state_dir/last-seen.json"
digest_file="$state_dir/digest.md"
mkdir -p "$state_dir"
exec 9>"$state_dir/run.lock"
flock -n 9 || exit 0

state='{"lastMonitorEventId":"","lastAgentEventId":"","incidentKey":"","unreachable":0}'
if [[ -s $state_file ]] && jq -e 'type == "object"' "$state_file" >/dev/null 2>&1; then
  state=$(jq -c '{lastMonitorEventId:(.lastMonitorEventId // ""),lastAgentEventId:(.lastAgentEventId // ""),incidentKey:(.incidentKey // ""),unreachable:(.unreachable // 0)}' "$state_file")
fi
write_state() {
  local value=$1 tmp
  tmp=$(mktemp "$state_dir/.last-seen.XXXXXX") || return 1
  if ! printf '%s\n' "$value" > "$tmp" || ! mv "$tmp" "$state_file"; then
    rm -f "$tmp"
    return 1
  fi
}
write_digest() {
  local content=$1 tmp
  tmp=$(mktemp "$state_dir/.digest.XXXXXX") || return 1
  if ! printf '%s\n' "$content" > "$tmp" || ! mv -T "$tmp" "$digest_file" 2>/dev/null; then
    rm -f "$tmp"
    return 1
  fi
}

fetch() { curl --fail --silent --show-error --max-time 10 "$1"; }
status=$(fetch "$base_url/status.json" 2>/dev/null) || status=
events=$(fetch "$base_url/events.json" 2>/dev/null) || events=
if [[ -z $status || -z $events ]] || ! jq -e 'type == "object"' <<<"$status" >/dev/null 2>&1 || ! jq -e 'type == "array"' <<<"$events" >/dev/null 2>&1; then
  unreachable=$(jq -r '.unreachable' <<<"$state")
  if (( unreachable < 2 )); then
    unreachable=$((unreachable + 1))
  fi
  state=$(jq -c --argjson count "$unreachable" '.unreachable = $count' <<<"$state")
  write_state "$state" || exit 0
  if (( unreachable == 2 )) && [[ $(jq -r '.unreachable' "$state_file") == 2 ]] && [[ ! -e "$state_dir/.unreachable-notified" ]]; then
    if notify-send --urgency=critical 'Vasher is unreachable' 'Two consecutive supervisor polls failed.'; then
      : > "$state_dir/.unreachable-notified"
    fi
  fi
  exit 0
fi

rm -f "$state_dir/.unreachable-notified"
state=$(jq -c '.unreachable = 0' <<<"$state")
write_state "$state" || exit 0

agent_events=$(fetch "$base_url/agent-events.json" 2>/dev/null) || agent_events='[]'
jq -e 'type == "array"' <<<"$agent_events" >/dev/null 2>&1 || agent_events='[]'
log=$(fetch "$base_url/log.txt" 2>/dev/null) || log=

monitor_id=$(jq -r '.[0].id // ""' <<<"$events")
agent_id=$(jq -r '.[0].id // ""' <<<"$agent_events")
last_monitor=$(jq -r '.lastMonitorEventId' <<<"$state")
last_agent=$(jq -r '.lastAgentEventId' <<<"$state")
status_state=$(jq -r '.state // "unknown"' <<<"$status")
revision=$(jq -r '.revision // .candidateRevision // ""' <<<"$status")
incident_key=
case "$status_state" in
  failed|stale|needs-attention|blocked) incident_key="$status_state:$revision" ;;
esac
old_incident=$(jq -r '.incidentKey' <<<"$state")

work=$digest_run
if [[ -n $monitor_id && $monitor_id != "$last_monitor" ]]; then work=true; fi
if [[ -n $agent_id && $agent_id != "$last_agent" ]]; then work=true; fi
if [[ -n $incident_key && $incident_key != "$old_incident" ]]; then work=true; fi
$work || exit 0

merged=$(jq -cn --argjson monitor "$events" --argjson agent "$agent_events" '
  [($monitor[] | . + {source:(.source // "monitor")}), ($agent[] | . + {source:(.source // "agent")})]
  | sort_by(.timestamp // "") | reverse | .[:3]')
# Use the monitor's header/query patterns and cover common key-value secret fields.
redacted_log=$(printf '%s' "$log" | tail -n 200 | jq -Rs '
  gsub("(?im)(?<prefix>^authorization:\\s*(?:bearer|token)\\s+)\\S+"; "\(.prefix)[REDACTED]")
  | gsub("(?im)(?<prefix>^x-api-key:\\s*)\\S+"; "\(.prefix)[REDACTED]")
  | gsub("(?i)(?<prefix>[?&](?:access_token|token|key|credential)=)[^&\\s]+"; "\(.prefix)[REDACTED]")
  | gsub("(?i)(?<prefix>\\b(?:secret|password|token|credential)\\s*[=:]\\s*)[^&\\s]+"; "\(.prefix)[REDACTED]")')
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
error_file="$state_dir/.hermes-error"
# Untrusted build and event text enters the prompt; Hermes gets no shell,
# file, or network toolset.
if output=$(timeout 300 hermes --toolsets todo --ignore-rules --skills vasher-supervisor --oneshot "$prompt" 2>"$error_file"); then
  if ! write_digest "$output"; then
    rm -f "$error_file"
    exit 0
  fi
else
  model_error=$(cat "$error_file")
  fallback=$(printf '# Vasher raw evidence fallback\n\nInference error: %s\n\n~~~json\n%s\n~~~\n' "$model_error" "$evidence")
  if ! write_digest "$fallback"; then
    rm -f "$error_file"
    exit 0
  fi
fi
rm -f "$error_file"

next_state=$(jq -c --arg monitor "$monitor_id" --arg agent "$agent_id" --arg incident "$incident_key" \
  '.lastMonitorEventId=$monitor | .lastAgentEventId=$agent | .incidentKey=$incident' <<<"$state")
write_state "$next_state" || exit 0

severity=$(jq -nr --arg state "$status_state" --argjson events "$merged" '
  if ($state == "failed" or $state == "needs-attention" or $state == "blocked") then "warning"
  elif any($events[]; ((.severity // "") == "critical" or (.severity // "") == "error" or (.severity // "") == "warning")) then "warning"
  else "informational" end')
if [[ $severity == warning ]]; then
  notify-send --urgency=critical 'Vasher needs attention' "State: $status_state. See $digest_file" || true
fi

if [[ -n $model_error ]]; then
  exit 0
fi
candidate=$(printf '%s\n' "$output" | jq -Rr 'select(length > 0)' | tail -n 1)
proposal=$(printf '%s' "$candidate" | jq -c -e 'select(type == "object")' 2>/dev/null) || exit 0
verb=$(jq -r '.verb // ""' <<<"$proposal")
input_name_re='^[A-Za-z0-9][A-Za-z0-9._-]{0,63}$'
case "$verb" in
  retry-exact)
    jq -e '((keys | sort) == ["revision","verb"]) and (.revision | test("^[0-9a-f]{40}$"))' <<<"$proposal" >/dev/null || exit 0
    ;;
  narrow-inputs)
    jq -e --arg name_re "$input_name_re" '
      ((keys | sort) == ["base","inputs","verb"])
      and (.base | test("^[0-9a-f]{40}$"))
      and (.inputs | type == "array" and length >= 1 and length <= 8
        and all(.[]; type == "string" and test($name_re))
        and length == (unique | length))' <<<"$proposal" >/dev/null || exit 0
    ;;
  hold-input)
    jq -e --arg name_re "$input_name_re" '
      ((keys | sort) == ["expires","input","reason","revision","verb"])
      and (.input | type == "string" and test($name_re))
      and (.revision | test("^[0-9a-f]{40}$"))
      and (.expires | test("^[0-9]{4}-[0-9]{2}-[0-9]{2}$"))
      and ((.reason | type) == "string")
      and (.reason | length > 0 and (test("[[:cntrl:]]") | not))' <<<"$proposal" >/dev/null || exit 0
    ;;
  release-input)
    jq -e --arg name_re "$input_name_re" '
      ((keys | sort) == ["input","verb"])
      and (.input | type == "string" and test($name_re))' <<<"$proposal" >/dev/null || exit 0
    ;;
  *) exit 0 ;;
esac
key="$HOME/.ssh/vasher-agent"
if [[ ! -f $key ]]; then
  printf '\nProposal retained: SSH key is missing at %s; no action was attempted.\n' "$key" >> "$digest_file"
  exit 0
fi
set +e
response=$(printf '%s\n' "$proposal" | ssh -o BatchMode=yes -o ConnectTimeout=10 -o StrictHostKeyChecking=yes -i "$key" vasher-agent@vasher.local.ryk.sh)
ssh_status=$?
set -e
printf '\nChannel response (exit %s): %s\n' "$ssh_status" "$response" >> "$digest_file"
exit 0
