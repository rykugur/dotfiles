#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

state_root=$tmp/state
events=$tmp/events
token_file=$tmp/github-token
printf 'test-token\n' > "$token_file"
mkdir -p "$state_root/repo/.git" "$state_root/worktrees/candidate/.git" "$tmp/bin"

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
if [[ ${1-} == build ]]; then
  printf 'build\n' >> "$EVENTS"
  exit 42
fi
EOF

cat > "$tmp/bin/nix-collect-garbage" <<'EOF'
#!/usr/bin/env bash
printf 'gc\n' >> "$EVENTS"
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
  bash "$tmp/prebuild.sh" candidate
exit_code=$?
set -e

[[ $exit_code -eq 42 ]] || {
  printf 'expected build exit 42, got: %s\n' "$exit_code" >&2
  exit 1
}
actual_events=$(<"$events")
[[ $actual_events == $'gc\nbuild\ngc' ]] || {
  printf 'expected cleanup/build/cleanup, got: %q\n' "$actual_events" >&2
  exit 1
}
jq -e '
  .state == "failed" and
  .baseRevision == "1111111111111111111111111111111111111111" and
  .revision == "2222222222222222222222222222222222222222" and
  .exitCode == 42
' "$state_root/dashboard/status.json" >/dev/null
