#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

state_root=$tmp/state
events=$tmp/events
token_file=$tmp/github-token
base=1111111111111111111111111111111111111111
candidate=2222222222222222222222222222222222222222
printf 'test-token\n' > "$token_file"
mkdir -p "$state_root/repo/.git" "$state_root/worktrees/candidate/.git" "$tmp/bin"

cat > "$tmp/bin/git" <<'EOF'
#!/usr/bin/env bash
case "$*" in
  *"rev-parse HEAD"*) printf '2222222222222222222222222222222222222222\n' ;;
esac
EOF

cat > "$tmp/bin/nix" <<'EOF'
#!/usr/bin/env bash
if [[ ${NIX_CONFIG-} != *'access-tokens = github.com=test-token'* ]]; then
  printf 'missing GitHub access token\n' >&2
  exit 99
fi
case "${1-} ${2-}" in
  'flake update') printf 'flake update\n' >> "$EVENTS" ;;
  'build '*)
    printf 'build\n' >> "$EVENTS"
    exit 42
    ;;
esac
EOF

cat > "$tmp/bin/nix-collect-garbage" <<'EOF'
#!/usr/bin/env bash
printf 'gc\n' >> "$EVENTS"
EOF

cat > "$tmp/bin/omp-updater" <<'EOF'
#!/usr/bin/env bash
printf 'omp update\n' >> "$EVENTS"
EOF

source_text=$(<"$repo_root/modules/nixos/vasher-prebuild.sh")
printf '%s\n' "${source_text//\/var\/lib\/vasher/$state_root}" > "$tmp/prebuild.sh"
chmod +x "$tmp/bin/"*

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
  bash "$tmp/prebuild.sh" retry "$base" "$candidate"
exit_code=$?
set -e

[[ $exit_code -eq 42 ]] || {
  printf 'expected build exit 42, got: %s\n' "$exit_code" >&2
  exit 1
}
actual_events=$(<"$events")
[[ $actual_events == $'gc\nbuild\ngc' ]] || {
  printf 'expected cleanup/build/cleanup without updates, got: %q\n' "$actual_events" >&2
  exit 1
}
jq -e --arg base "$base" --arg candidate "$candidate" '
  .state == "failed" and
  .mode == "retry" and
  .baseRevision == $base and
  .revision == $candidate and
  .exitCode == 42
' "$state_root/dashboard/status.json" >/dev/null
