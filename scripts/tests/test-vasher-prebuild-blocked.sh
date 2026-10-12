#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

state_root=$tmp/state
events=$tmp/events
token_file=$tmp/github-token
worktree=$state_root/worktrees/candidate
printf 'test-token\n' > "$token_file"
mkdir -p "$tmp/bin"

# Every build tool records its invocation, so the assertions can prove the
# blocked run touched neither the repository nor the Nix store.
for binary in git nix nix-collect-garbage omp-updater; do
  cat > "$tmp/bin/$binary" <<EOF
#!/usr/bin/env bash
printf '$binary %s\n' "\$*" >> "\$EVENTS"
exit 0
EOF
done

source_text=$(<"$repo_root/modules/nixos/vasher-prebuild.sh")
printf '%s\n' "${source_text//\/var\/lib\/vasher/$state_root}" > "$tmp/prebuild.sh"
chmod +x "$tmp/bin/"*

run_case() {
  local mode=$1
  rm -rf "$state_root"
  mkdir -p "$state_root/repo/.git" "$worktree/.git" "$state_root/monitor"
  : > "$events"
  printf '{"revision":"%s","pattern":"I/O error","at":"2026-10-12T00:00:00Z"}\n' \
    "$(printf '2%.0s' {1..40})" > "$state_root/monitor/storage-fault.json"

  local exit_code=0
  set +e
  PATH="$tmp/bin:$PATH" \
    EVENTS="$events" \
    REPO_URL=unused \
    TARGET_ATTR=unused \
    CACHE_BRANCH=cache-bump \
    KEEP_ROOTS=1 \
    EXCLUDED_PACKAGES='[]' \
    GITHUB_TOKEN_FILE="$token_file" \
    OMP_UPDATER="$tmp/bin/omp-updater" \
    bash "$tmp/prebuild.sh" "$mode" > /dev/null 2>&1
  exit_code=$?
  set -e
  printf '%s\n' "$exit_code"
}

fail() {
  printf '%s\n' "$1" >&2
  exit 1
}

for mode in refresh candidate narrow; do
  exit_code=$(run_case "$mode")

  [[ $exit_code -eq 0 ]] ||
    fail "$mode: expected exit 0, got $exit_code"

  state=$(jq -r .state "$state_root/dashboard/status.json")
  [[ $state == blocked ]] ||
    fail "$mode: expected status state blocked, got $state"

  status_mode=$(jq -r .mode "$state_root/dashboard/status.json")
  [[ $status_mode == "$mode" ]] ||
    fail "$mode: expected status mode $mode, got $status_mode"

  ! grep -q 'git fetch' "$events" ||
    fail "$mode: blocked run called git fetch"

  ! grep -q '^nix build' "$events" ||
    fail "$mode: blocked run called nix build"

  [[ ! -s $events ]] ||
    fail "$mode: blocked run called build tools: $(tr '\n' ';' < "$events")"

  [[ -e $state_root/monitor/storage-fault.json ]] ||
    fail "$mode: blocked run removed the storage fault file"

  history=$(jq -r 'length' "$state_root/dashboard/history.json")
  [[ $history -eq 0 ]] ||
    fail "$mode: blocked run appended $history history entries"
done

printf 'test-vasher-prebuild-blocked: all modes blocked\n'
