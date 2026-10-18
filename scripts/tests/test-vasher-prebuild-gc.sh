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
