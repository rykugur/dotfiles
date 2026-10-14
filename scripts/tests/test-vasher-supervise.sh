#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
SCRIPT="$ROOT/modules/ai/vasher-supervise.sh"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
BIN="$TMP/bin"
mkdir -p "$BIN"

cat > "$BIN/curl" <<'STUB'
#!/usr/bin/env bash
url=${!#}
case "$url" in
  */api/status.json) file=$FIXTURE/status.json ;;
  */api/events.json) file=$FIXTURE/events.json ;;
  */api/agent-events.json) file=$FIXTURE/agent-events.json ;;
  */api/log.txt) file=$FIXTURE/log.txt ;;
  *) exit 22 ;;
esac
if [[ -f "$FIXTURE/fail-all" || ( "$url" == */api/status.json && -f "$FIXTURE/fail-status" ) || ( "$url" == */api/events.json && -f "$FIXTURE/fail-events" ) ]]; then
  exit 7
fi
if [[ "$url" == */api/agent-events.json && -f "$FIXTURE/fail-agent-events" ]]; then exit 22; fi
if [[ "$url" == */api/log.txt && -f "$FIXTURE/fail-log" ]]; then exit 22; fi
cat "$file"
STUB
cat > "$BIN/hermes" <<'STUB'
#!/usr/bin/env bash
if [[ ${1-} == send ]]; then
  printf '%s\n' "$*" >> "$CALLS/hermes-send"
  [[ ! -f "$FIXTURE/send-fail" ]]
  exit $?
fi
printf 'call\n' >> "$CALLS/hermes"
[[ $# -eq 7 ]] || { echo "prompt was not one argument" >&2; exit 97; }
[[ $1 == --toolsets && $2 == todo && $3 == --ignore-rules && $4 == --skills && $5 == vasher-supervisor && $6 == --oneshot ]] || {
  echo "unsafe Hermes invocation" >&2
  exit 98
}
printf '%s\n' "$1 $2 $3 $4 $5 $6" > "$CALLS/hermes-args"
printf '%s' "$7" > "$CALLS/prompt"
if [[ -f "$FIXTURE/hermes-fail" ]]; then echo 'inference unavailable' >&2; exit 9; fi
cat "$FIXTURE/hermes-output"
STUB
cat > "$BIN/timeout" <<'STUB'
#!/usr/bin/env bash
printf '%s\n' "$1" >> "$CALLS/timeout"
shift
exec "$@"
STUB
cat > "$BIN/logger" <<'STUB'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$CALLS/notify"
[[ ! -f "$FIXTURE/notify-fail" ]]
STUB
cat > "$BIN/ssh" <<'STUB'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$CALLS/ssh"
cat >> "$CALLS/ssh-stdin"
printf '{"accepted":false,"reason":"busy","eventId":"a-reject"}\n'
exit 1
STUB
chmod +x "$BIN"/*

pass=0
run_case() {
  local name=$1 status=${2:-success} monitor=${3:-m1} agent=${4:-a1}
  local seen_monitor=${5:-$monitor} seen_agent=${6:-$agent}
  CASE="$TMP/$name"; FIXTURE="$CASE/fixture"; CALLS="$CASE/calls"; STATE="$CASE/state"
  mkdir -p "$FIXTURE" "$CALLS" "$STATE"
  printf '{"state":"%s","revision":"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa","updatedAt":"2026-10-12T08:00:00Z","severity":"informational"}\n' "$status" > "$FIXTURE/status.json"
  printf '[{"id":"%s","timestamp":"2026-10-12T08:00:00Z","severity":"informational"}]\n' "$monitor" > "$FIXTURE/events.json"
  printf '[{"id":"%s","timestamp":"2026-10-12T08:00:01Z","severity":"informational"}]\n' "$agent" > "$FIXTURE/agent-events.json"
  printf 'old\nAuthorization: Bearer badsecret\nx-api-key: badkey\nurl?a=1&token=badtoken&credential=badcredential\nsecret=badvalue\nnew\n' > "$FIXTURE/log.txt"
  printf 'Summary\n\nNo action.\n' > "$FIXTURE/hermes-output"
  printf '{"lastMonitorEventId":"%s","lastAgentEventId":"%s","incidentKey":"","unreachable":0}\n' "$seen_monitor" "$seen_agent" > "$STATE/last-seen.json"
  export FIXTURE CALLS VASHER_SUPERVISE_STATE="$STATE" PATH="$BIN:$PATH" HOME="$CASE/home"
}
assert_calls() { local file=$1 expected=$2; local got=0; [[ -f "$CALLS/$file" ]] && got=$(wc -l < "$CALLS/$file"); [[ $got -eq $expected ]] || { echo "FAIL $CASE: $file calls $got != $expected"; printf '%s\n' '--- model output ---'; cat "$FIXTURE/hermes-output"; printf '%s\n' '--- digest ---'; cat "$STATE/digest.md" 2>/dev/null || true; exit 1; }; }
run() { bash "$SCRIPT" "$@"; }

run_case healthy-success success; run; assert_calls hermes 0
run_case healthy-idle idle; run; assert_calls hermes 0
run_case monitor-event success m2 a1 m1 a1; run; assert_calls hermes 1
run_case agent-event success m1 a2 m1 a1; run; assert_calls hermes 1
run_case failed failed; run; assert_calls hermes 1; jq '.updatedAt = "2026-10-12T08:15:00Z"' "$FIXTURE/status.json" > "$FIXTURE/status.next"; mv "$FIXTURE/status.next" "$FIXTURE/status.json"; run; assert_calls hermes 1
run_case blocked blocked; run; assert_calls hermes 1; assert_calls notify 1; jq '.updatedAt = "2026-10-12T08:15:00Z"' "$FIXTURE/status.json" > "$FIXTURE/status.next"; mv "$FIXTURE/status.next" "$FIXTURE/status.json"; run; assert_calls hermes 1; assert_calls notify 1
run_case event-error success m2 a1 m1 a1; jq '.[0].severity = "error"' "$FIXTURE/events.json" > "$FIXTURE/events.next"; mv "$FIXTURE/events.next" "$FIXTURE/events.json"; run; assert_calls notify 1
run_case send-target blocked; VASHER_SUPERVISE_SEND_TARGET=telegram run; assert_calls notify 1; assert_calls hermes-send 1; grep -q 'send -t telegram -s Vasher needs attention' "$CALLS/hermes-send" || { echo 'FAIL gateway alert shape'; exit 1; }
run_case send-unset blocked; run; assert_calls notify 1; [[ ! -e "$CALLS/hermes-send" ]] || { echo 'FAIL sent without a target'; exit 1; }
run_case digest success; run --digest; assert_calls hermes 1
grep -qx -- '--toolsets todo --ignore-rules --skills vasher-supervisor --oneshot' "$CALLS/hermes-args" || { echo 'FAIL Hermes CLI shape'; exit 1; }
grep -qx '300' "$CALLS/timeout" || { echo 'FAIL Hermes timeout'; exit 1; }

run_case monday-slot success m2 a1 m1 a1; VASHER_SUPERVISE_NOW='1 09:00' run; assert_calls hermes 0; VASHER_SUPERVISE_NOW='1 09:00' run --digest; assert_calls hermes 1

run_case busy-lock success m2 a1 m1 a1; before=$(cat "$STATE/last-seen.json"); exec 8>"$STATE/run.lock"; flock -n 8; run; assert_calls hermes 0; [[ $(cat "$STATE/last-seen.json") == "$before" ]]; flock -u 8; exec 8>&-

run_case unreachable success; touch "$FIXTURE/fail-all"; run; assert_calls notify 0; [[ $(jq -r .unreachable "$STATE/last-seen.json") == 1 ]]; touch "$FIXTURE/notify-fail"; run; assert_calls notify 1; [[ $(jq -r .unreachable "$STATE/last-seen.json") == 2 ]]; [[ ! -e "$STATE/.unreachable-notified" ]]; rm "$FIXTURE/notify-fail"; run; assert_calls notify 2; [[ -e "$STATE/.unreachable-notified" ]]; touch "$FIXTURE/notify-fail"; run; assert_calls notify 2; rm "$FIXTURE/fail-all"; run; [[ $(jq -r .unreachable "$STATE/last-seen.json") == 0 ]]; [[ ! -e "$STATE/.unreachable-notified" ]]

run_case model-failure failed; touch "$FIXTURE/hermes-fail"; run; assert_calls hermes 1; grep -q 'inference unavailable' "$STATE/digest.md"; run; assert_calls hermes 1

run_case degraded success m2 a2 m1 a1; touch "$FIXTURE/fail-agent-events" "$FIXTURE/fail-log"; run; assert_calls hermes 1

run_case redact success m2 a1 m1 a1; run; ! grep -Eq 'badsecret|badkey|badtoken|badcredential|badvalue' "$CALLS/prompt"; grep -Fq 'Authorization: Bearer [REDACTED]' "$CALLS/prompt"; grep -Fq 'x-api-key: [REDACTED]' "$CALLS/prompt"; grep -Fq 'token=[REDACTED]' "$CALLS/prompt"; grep -Fq 'credential=[REDACTED]' "$CALLS/prompt"

run_case missing-key failed; printf '%s\n' '{"verb":"retry-exact","revision":"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"}' > "$FIXTURE/hermes-output"; run; assert_calls ssh 0; grep -q 'Proposal retained: SSH key is missing' "$STATE/digest.md"

run_case rejection failed; mkdir -p "$HOME/.ssh"; : > "$HOME/.ssh/vasher-agent"; printf '%s\n' '{"verb":"retry-exact","revision":"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"}' > "$FIXTURE/hermes-output"; run; assert_calls ssh 1; grep -q '"accepted":false' "$STATE/digest.md"; assert_calls hermes 1
grep -Fq -- '-o BatchMode=yes -o ConnectTimeout=10 -o StrictHostKeyChecking=yes' "$CALLS/ssh"

run_case hold-other failed; mkdir -p "$HOME/.ssh"; : > "$HOME/.ssh/vasher-agent"; printf '%s\n' '{"verb":"hold-input","input":"home-manager","revision":"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa","expires":"2026-11-01","reason":"Pin regression"}' > "$FIXTURE/hermes-output"; run; assert_calls ssh 1
run_case release-other failed; mkdir -p "$HOME/.ssh"; : > "$HOME/.ssh/vasher-agent"; printf '%s\n' '{"verb":"release-input","input":"home-manager"}' > "$FIXTURE/hermes-output"; run; assert_calls ssh 1
run_case narrow-many failed; mkdir -p "$HOME/.ssh"; : > "$HOME/.ssh/vasher-agent"; printf '%s\n' '{"verb":"narrow-inputs","base":"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa","inputs":["nixpkgs","home-manager"]}' > "$FIXTURE/hermes-output"; run; assert_calls ssh 1
run_case narrow-duplicate failed; mkdir -p "$HOME/.ssh"; : > "$HOME/.ssh/vasher-agent"; printf '%s\n' '{"verb":"narrow-inputs","base":"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa","inputs":["nixpkgs","nixpkgs"]}' > "$FIXTURE/hermes-output"; run; assert_calls ssh 0
run_case invalid-input failed; mkdir -p "$HOME/.ssh"; : > "$HOME/.ssh/vasher-agent"; printf '%s\n' '{"verb":"release-input","input":"bad/input"}' > "$FIXTURE/hermes-output"; run; assert_calls ssh 0

run_case digest-write-failure success m2 a1 m1 a1; mkdir "$STATE/digest.md"; before=$(cat "$STATE/last-seen.json"); run; assert_calls hermes 1; [[ $(cat "$STATE/last-seen.json") == "$before" ]]

echo 'PASS: vasher-supervise behavior'
