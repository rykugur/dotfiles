#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

state_root=$tmp/state
events=$tmp/events
mkdir -p "$state_root/repo/.git" "$state_root/worktrees/candidate/.git" "$tmp/bin"

cat > "$tmp/bin/git" <<'EOF'
#!/usr/bin/env bash
if [[ $* == *"rev-parse origin/master"* ]]; then
  printf 'base\n'
fi
EOF

cat > "$tmp/bin/nix" <<'EOF'
#!/usr/bin/env bash
if [[ ${1-} == build ]]; then
  printf 'build\n' >> "$EVENTS"
  exit 42
fi
EOF

cat > "$tmp/bin/nix-collect-garbage" <<'EOF'
#!/usr/bin/env bash
printf 'gc\n' >> "$EVENTS"
EOF

cat > "$tmp/bin/omp-updater" <<'EOF'
#!/usr/bin/env bash
exit 0
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
  OMP_UPDATER="$tmp/bin/omp-updater" \
  bash "$tmp/prebuild.sh" candidate
exit_code=$?
set -e

[[ $exit_code -eq 42 ]]
actual_events=$(<"$events")
[[ $actual_events == $'gc\nbuild\ngc' ]] || {
  printf 'expected cleanup/build/cleanup, got: %q\n' "$actual_events" >&2
  exit 1
}
jq -e '.state == "failed" and .exitCode == 42' "$state_root/dashboard/status.json" >/dev/null
