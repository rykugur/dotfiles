#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

state_root=$tmp/state
events=$tmp/events
token_file=$tmp/github-token
metadata=$tmp/metadata.json
worktree=$state_root/worktrees/narrow
request=$state_root/agent/narrow-request.json
holds=$state_root/agent/holds.json
status_json=$state_root/dashboard/status.json
base=1111111111111111111111111111111111111111
today=$(date +%F)
tomorrow=$(date -d "$today + 1 day" +%F)
printf 'test-token\n' > "$token_file"
mkdir -p "$tmp/bin"

cat > "$metadata" <<'EOF'
{
  "locks": {
    "nodes": {
      "root": {
        "inputs": {
          "nixpkgs": "nixpkgs",
          "home-manager": "home-manager",
          "stylix": "stylix",
          "oh-my-pi": "oh-my-pi"
        }
      }
    }
  }
}
EOF

cat > "$tmp/bin/git" <<'EOF'
#!/usr/bin/env bash
case "$*" in
  *"rev-parse origin/master"*) printf '%s\n' "${ORIGIN_MASTER:-1111111111111111111111111111111111111111}" ;;
  *"rev-parse HEAD"*) printf '2222222222222222222222222222222222222222\n' ;;
  *"diff --cached --quiet"*) exit 1 ;;
  *push*) printf 'push\n' >> "$EVENTS" ;;
esac
EOF

cat > "$tmp/bin/nix" <<'EOF'
#!/usr/bin/env bash
if [[ ${NIX_CONFIG-} != *'access-tokens = github.com=test-token'* ]]; then
  printf 'missing GitHub access token\n' >&2
  exit 99
fi
if [[ ${1-} == flake ]]; then
  printf '%s\n' "$*" >> "$EVENTS"
  if [[ ${2-} == metadata ]]; then
    if [[ "$*" != "flake metadata --json --no-write-lock-file $WORKTREE" ]]; then
      printf 'unexpected flake metadata argv: %s\n' "$*" >&2
      exit 1
    fi
    cat "$METADATA_JSON"
  fi
  exit 0
fi
if [[ ${1-} == build ]]; then
  printf 'build\n' >> "$EVENTS"
  [[ ${BUILD_FAIL-} == 1 ]] && exit 7
  printf '/nix/store/aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa-jezrien\n'
  exit 0
fi
EOF

cat > "$tmp/bin/nix-store" <<'EOF'
#!/usr/bin/env bash
# `nix-store --add-root <path> --indirect --realise <out>`: just create <path>.
[[ ${1-} == --add-root ]] && : > "$2"
exit 0
EOF

cat > "$tmp/bin/nix-collect-garbage" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF

cat > "$tmp/bin/omp-updater" <<'EOF'
#!/usr/bin/env bash
printf 'omp-updater\n' >> "$EVENTS"
exit 0
EOF

source_text=$(<"$repo_root/modules/nixos/vasher-prebuild.sh")
printf '%s\n' "${source_text//\/var\/lib\/vasher/$state_root}" > "$tmp/prebuild.sh"
chmod +x "$tmp/bin/"*

hold() {
  printf '{"%s":{"revision":"3333333333333333333333333333333333333333","expires":"%s","reason":"pinned for test","createdAt":"2026-10-12T00:00:00+00:00"}}\n' \
    "$1" "$2"
}

# Prints the recorded `nix flake update` arguments with the input names sorted,
# so assertions do not depend on the order jq emits them in.
update_call() {
  local line prefix
  local -a words names
  line=$(grep -m1 -E '^flake update( |$)' "$events" || true)
  [[ -n $line ]] || {
    printf 'no flake update call recorded\n' >&2
    return 1
  }
  read -r -a words <<< "$line"
  prefix="${words[*]:0:4}"
  names=("${words[@]:4}")
  if ((${#names[@]})); then
    mapfile -t names < <(printf '%s\n' "${names[@]}" | sort)
    printf '%s %s\n' "$prefix" "${names[*]}"
  else
    printf '%s\n' "$prefix"
  fi
}

# request_json, holds_json, ORIGIN_MASTER and BUILD_FAIL come from the caller.
exit_code=0
run_case() {
  local request_json=$1 holds_json=$2
  rm -rf "$state_root"
  mkdir -p "$state_root/repo/.git" "$worktree/.git" "$state_root/agent"
  : > "$events"
  [[ $request_json == none ]] || printf '%s\n' "$request_json" > "$request"
  [[ -z $holds_json ]] || printf '%s\n' "$holds_json" > "$holds"

  exit_code=0
  set +e
  PATH="$tmp/bin:$PATH" \
    EVENTS="$events" \
    METADATA_JSON="$metadata" \
    ORIGIN_MASTER="${ORIGIN_MASTER-}" \
    BUILD_FAIL="${BUILD_FAIL-}" \
    REPO_URL=unused \
    TARGET_ATTR=unused \
    CACHE_BRANCH=cache-bump \
    KEEP_ROOTS=1 \
    EXCLUDED_PACKAGES='[]' \
    GITHUB_TOKEN_FILE="$token_file" \
    OMP_UPDATER="$tmp/bin/omp-updater" \
    WORKTREE="$worktree" \
    bash "$tmp/prebuild.sh" narrow > /dev/null 2>&1
  exit_code=$?
  set -e
}

fail() {
  printf '%s\n' "$1" >&2
  exit 1
}

request_for() {
  local names
  names=$(printf '%s\n' "$@" | jq -R . | jq -sc .)
  printf '{"base":"%s","inputs":%s}\n' "$base" "$names"
}

# 1-3: a valid request updates exactly the named inputs, skips the OMP updater,
# and records mode "narrow".
run_case "$(request_for nixpkgs stylix)" ''
((exit_code == 0)) || fail "valid request: expected exit 0, got $exit_code"
actual=$(update_call)
[[ $actual == "flake update --flake $worktree nixpkgs stylix" ]] ||
  fail "valid request: unexpected update call: $actual"
! grep -qx omp-updater "$events" || fail 'valid request: OMP updater ran'
[[ $(jq -r .mode "$status_json") == narrow ]] || fail 'valid request: status mode is not narrow'

# 4: a held name drops out, the rest still go through.
run_case "$(request_for nixpkgs stylix)" "$(hold nixpkgs "$tomorrow")"
((exit_code == 0)) || fail "partial hold: expected exit 0, got $exit_code"
actual=$(update_call)
[[ $actual == "flake update --flake $worktree stylix" ]] ||
  fail "partial hold: unexpected update call: $actual"

# 5: nothing left to update is an error, and it is reported as a failure.
run_case "$(request_for nixpkgs)" "$(hold nixpkgs "$tomorrow")"
((exit_code != 0)) || fail 'all held: expected non-zero exit'
! grep -qx build "$events" || fail 'all held: reached nix build'
[[ $(jq -r .state "$status_json") == failed ]] || fail 'all held: status state is not failed'

# 6: the request must name the current origin/master.
ORIGIN_MASTER=4444444444444444444444444444444444444444
run_case "$(request_for nixpkgs)" ''
unset ORIGIN_MASTER
((exit_code != 0)) || fail 'stale base: expected non-zero exit'
! grep -qx build "$events" || fail 'stale base: reached nix build'

# 7: a missing request file is a usage error.
run_case none ''
((exit_code == 2)) || fail "missing request: expected exit 2, got $exit_code"

# 8: so is a base that is not a 40 hex revision.
run_case '{"base":"deadbeef","inputs":["nixpkgs"]}' ''
((exit_code == 2)) || fail "bad base: expected exit 2, got $exit_code"

# 9: a failed build never publishes the candidate.
BUILD_FAIL=1
run_case "$(request_for nixpkgs)" ''
unset BUILD_FAIL
((exit_code != 0)) || fail 'build failure: expected non-zero exit'
grep -qx build "$events" || fail 'build failure: nix build never ran'
! grep -qx push "$events" || fail 'build failure: pushed anyway'

printf 'ok\n'
