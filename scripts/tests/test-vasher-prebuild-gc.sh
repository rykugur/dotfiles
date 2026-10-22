#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

state_root=$tmp/state
token_file=$tmp/github-token
cached_path=$tmp/partially-substituted-path
available_file=$tmp/available-bytes
base=1111111111111111111111111111111111111111
candidate=2222222222222222222222222222222222222222
printf 'test-token\n' > "$token_file"
mkdir -p "$state_root/repo/.git" "$state_root/worktrees/candidate/.git" "$state_root/dashboard" "$tmp/bin"

cat > "$tmp/bin/git" <<'EOF'
#!/usr/bin/env bash
case "$*" in
  *"rev-parse origin/master"*) printf '1111111111111111111111111111111111111111\n' ;;
  *"rev-parse HEAD"*) printf '2222222222222222222222222222222222222222\n' ;;
  *"diff --cached --quiet"*) exit 1 ;;
esac
EOF

cat > "$tmp/bin/nix" <<'EOF'
#!/usr/bin/env bash
if [[ ${NIX_CONFIG-} != *'access-tokens = github.com=test-token'* ]]; then
  printf 'missing GitHub access token\n' >&2
  exit 99
fi
if [[ ${1-} == build && ${NOISY_LOG-} == 1 ]]; then
  {
  printf 'Authorization: Bearer bearer-secret\nx-api-key: api-secret\n'
  printf 'request https://example.org/?access_token=url-secret\n'
  printf 'access-tokens = github.com=test-token\n'
  for ((i = 0; i < 220; i++)); do
    printf 'Authorization: Bearer bearer-secret line %03d\n' "$i"
  done
  printf '%040000d\n' 0
  printf 'Authorization: Bearer bearer-secret\nx-api-key: api-secret\n'
  printf 'request https://example.org/?access_token=url-secret\n'
  printf 'access-tokens = github.com=test-token\n'
  } >&2
fi
[[ ${1-} == build ]] && exit 42
exit 0
EOF

cat > "$tmp/bin/stat" <<'EOF'
#!/usr/bin/env bash
read -r bytes < "$AVAILABLE_FILE"
printf '%s 4096\n' "$((bytes / 4096))"
EOF

cat > "$tmp/bin/nix-collect-garbage" <<'EOF'
#!/usr/bin/env bash
rm -f "$CACHED_PATH"
if [[ -n ${FREE_AFTER_GC-} ]]; then
  printf '%s\n' "$FREE_AFTER_GC" > "$AVAILABLE_FILE"
fi
EOF

real_tee=$(command -v tee)
cat > "$tmp/bin/tee" <<'EOF'
#!/usr/bin/env bash
[[ ${SLOW_TEE-} == 1 ]] && sleep 0.2
exec "$REAL_TEE" "$@"
EOF

source_text=$(<"$repo_root/modules/nixos/vasher-prebuild.sh")
printf '%s\n' "${source_text//\/var\/lib\/vasher/$state_root}" > "$tmp/prebuild.sh"
chmod +x "$tmp/bin/"*

run_build() {
  local code
  set +e
  PATH="$tmp/bin:$PATH" \
    AVAILABLE_FILE="$available_file" \
    CACHED_PATH="$cached_path" \
    FREE_AFTER_GC="${FREE_AFTER_GC-}" \
    REAL_TEE="$real_tee" \
    SLOW_TEE="${SLOW_TEE-}" \
    REPO_URL=unused \
    TARGET_ATTR=unused \
    CACHE_BRANCH=cache-bump \
    KEEP_ROOTS=1 \
    EXCLUDED_PACKAGES='[]' \
    GITHUB_TOKEN_FILE="$token_file" \
    bash "$tmp/prebuild.sh" "$@"
  code=$?
  set -e
  return "$code"
}

# A skipped refresh must not truncate the log belonging to a build holding
# the same lock; this keeps each archive tied to its own run.
printf 'running-output\n' > "$state_root/dashboard/current.log"
exec 8>"$state_root/prebuild.lock"
flock -x 8
run_build refresh > /dev/null 2>&1 || exit 1
[[ $(<"$state_root/dashboard/current.log") == running-output ]] || {
  printf 'skipped refresh cleared the active run log\n' >&2
  exit 1
}
flock -u 8

# A failed candidate and its exact retry must retain downloads while there
# is room on disk; otherwise each attempt starts the large closure from zero.
printf 'cached bytes\n' > "$cached_path"
printf '%s\n' "$((60 * 1024 ** 3))" > "$available_file"
run_build candidate && exit 1 || code=$?
[[ $code -eq 42 && $(<"$cached_path") == 'cached bytes' ]] || {
  printf 'failed candidate discarded a reusable store path\n' >&2
  exit 1
}
run_build retry "$base" "$candidate" && exit 1 || code=$?
[[ $code -eq 42 && $(<"$cached_path") == 'cached bytes' ]] || {
  printf 'exact retry discarded a reusable store path\n' >&2
  exit 1
}
jq -e --arg revision "$candidate" '
  .state == "failed" and .mode == "retry" and .revision == $revision and .exitCode == 42
' "$state_root/dashboard/status.json" >/dev/null
jq -e 'has("id") | not' "$state_root/dashboard/status.json" >/dev/null
jq -e 'has("logPath") | not' "$state_root/dashboard/status.json" >/dev/null
jq -e 'has("id") | not' "$state_root/last-build.json" >/dev/null

# If less than 45 GiB is free, reclaim before another build. If reclaim
# cannot restore that reserve, do not launch the build at all.
printf '%s\n' "$((44 * 1024 ** 3))" > "$available_file"
FREE_AFTER_GC="$((50 * 1024 ** 3))" run_build candidate && exit 1 || code=$?
[[ $code -eq 42 && ! -e $cached_path ]] || {
  printf 'low-space run did not reclaim before building\n' >&2
  exit 1
}
printf '%s\n' "$((44 * 1024 ** 3))" > "$available_file"
FREE_AFTER_GC="$((44 * 1024 ** 3))" run_build candidate && exit 1 || code=$?
[[ $code -eq 1 ]] || {
  printf 'build ran without its disk reserve: exit %s\n' "$code" >&2
  exit 1
}

# Each terminal run keeps a separately addressable, redacted log; adding the
# 21st terminal entry removes its associated archive, not an unrelated file.
first_id=$(jq -r '.[-1].id' "$state_root/dashboard/history.json")
[[ $first_id =~ ^[A-Za-z0-9_-]+$ ]] || {
  printf 'terminal history missing a safe run id\n' >&2
  exit 1
}
[[ -f $state_root/dashboard/runs/$first_id.txt ]] || exit 1
printf 'do not delete\n' > "$state_root/dashboard/runs/not.safe.txt"
printf 'incomplete archive\n' > "$state_root/dashboard/runs/orphan-safe.txt"
jq '[{"state":"legacy","mode":"candidate"}] + .' \
  "$state_root/dashboard/history.json" > "$tmp/history-with-legacy"
mv "$tmp/history-with-legacy" "$state_root/dashboard/history.json"

for ((i = 0; i < 20; i++)); do
  run_build candidate > /dev/null 2>&1 && exit 1 || code=$?
  [[ $code -eq 1 ]] || exit 1
  if ((i == 0)); then
    jq -e '.[1].state == "legacy" and (.[1] | has("logPath") | not)' \
      "$state_root/dashboard/history.json" >/dev/null
    [[ ! -e $state_root/dashboard/runs/orphan-safe.txt ]] || {
      printf 'orphaned archive was not pruned\n' >&2
      exit 1
    }
  fi
done
jq -e 'length == 20 and all(.[]; (.id | test("^[A-Za-z0-9_-]+$")) and
  .logPath == ("/api/runs/" + .id + ".txt"))' \
  "$state_root/dashboard/history.json" >/dev/null
[[ ! -e $state_root/dashboard/runs/$first_id.txt ]] || {
  printf 'pruned run archive remains on disk\n' >&2
  exit 1
}
[[ -f $state_root/dashboard/runs/not.safe.txt ]] || exit 1
[[ $(find "$state_root/dashboard/runs" -maxdepth 1 -type f -name 'run-*.txt' | wc -l) -eq 20 ]] || {
  printf 'archived run count does not match retained history\n' >&2
  exit 1
}

# Exercise line/byte bounds and known secrets in the terminal snapshot.
printf '%s\n' "$((60 * 1024 ** 3))" > "$available_file"
SLOW_TEE=1 NOISY_LOG=1 run_build candidate > /dev/null 2>&1 && exit 1 || code=$?
[[ $code -eq 42 ]] || exit 1
recent_id=$(jq -r '.[0].id' "$state_root/dashboard/history.json")
recent_log="$state_root/dashboard/runs/$recent_id.txt"
[[ -f $recent_log && -f $state_root/dashboard/log.txt ]] || exit 1
cmp "$recent_log" "$state_root/dashboard/log.txt" || exit 1
[[ $(wc -c < "$recent_log") -le 32768 ]] || exit 1
[[ $(wc -l < "$recent_log") -le 200 ]] || exit 1
grep -Fq '[REDACTED]' "$recent_log" || exit 1
for secret in test-token bearer-secret api-secret url-secret; do
  if grep -Fq "$secret" "$recent_log"; then
    printf 'archived log exposed %s\n' "$secret" >&2
    exit 1
  fi
done

# A failed archive must not advertise a broken link or turn a finished run
# into a different result.
mv "$state_root/dashboard/runs" "$tmp/saved-runs"
: > "$state_root/dashboard/runs"
run_build candidate > /dev/null 2>&1 && exit 1 || code=$?
[[ $code -eq 42 ]] || exit 1
jq -e '.[0].state == "failed" and (.[0] | has("logPath") | not)' \
  "$state_root/dashboard/history.json" >/dev/null
mv "$state_root/dashboard/runs" "$tmp/runs-blocker"
mv "$tmp/saved-runs" "$state_root/dashboard/runs"
