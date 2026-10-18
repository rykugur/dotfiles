#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

state_root=$tmp/state
token_file=$tmp/github-token
base=1111111111111111111111111111111111111111
candidate=3333333333333333333333333333333333333333
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
printf 'retry must not build from the wrong worktree\n' >&2
exit 99
EOF

source_text=$(<"$repo_root/modules/nixos/vasher-prebuild.sh")
printf '%s\n' "${source_text//\/var\/lib\/vasher/$state_root}" > "$tmp/prebuild.sh"
chmod +x "$tmp/bin/"*

set +e
PATH="$tmp/bin:$PATH" \
  REPO_URL=unused \
  TARGET_ATTR=unused \
  CACHE_BRANCH=cache-bump \
  KEEP_ROOTS=1 \
  EXCLUDED_PACKAGES='[]' \
  GITHUB_TOKEN_FILE="$token_file" \
  bash "$tmp/prebuild.sh" retry "$base" "$candidate"
exit_code=$?
set -e

[[ $exit_code -eq 1 ]] || {
  printf 'mismatched retry was not rejected: exit %s\n' "$exit_code" >&2
  exit 1
}
[[ ! -e $state_root/dashboard/status.json ]] || {
  printf 'mismatched retry reached build preparation\n' >&2
  exit 1
}
