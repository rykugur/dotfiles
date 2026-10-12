#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

state_root=$tmp/state
events=$tmp/events
token_file=$tmp/github-token
metadata=$tmp/metadata.json
worktree=$state_root/worktrees/candidate
today=$(date +%F)
yesterday=$(date -d "$today - 1 day" +%F)
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
  exit 42
fi
EOF

cat > "$tmp/bin/nix-collect-garbage" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF

cat > "$tmp/bin/omp-updater" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF

source_text=$(<"$repo_root/modules/nixos/vasher-prebuild.sh")
printf '%s\n' "${source_text//\/var\/lib\/vasher/$state_root}" > "$tmp/prebuild.sh"
chmod +x "$tmp/bin/"*

hold() {
  printf '{"%s":{"revision":"3333333333333333333333333333333333333333","expires":"%s","reason":"pinned for test","createdAt":"2026-10-12T00:00:00+00:00"}}\n' \
    "$1" "$2"
}

hold_all() {
  jq -n --arg e "$1" '
    ["nixpkgs", "home-manager", "stylix", "oh-my-pi"]
    | map({
        key: .,
        value: {
          revision: "3333333333333333333333333333333333333333",
          expires: $e,
          reason: "pinned for test",
          createdAt: "2026-10-12T00:00:00+00:00"
        }
      })
    | from_entries'
}

# Prints the recorded `nix flake update` arguments with the input names sorted,
# so assertions do not depend on the order jq emits them in.
update_call() {
  local line words prefix
  local -a names
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

run_case() {
  local holds_json=$1
  rm -rf "$state_root"
  mkdir -p "$state_root/repo/.git" "$worktree/.git" "$state_root/agent"
  : > "$events"
  if [[ -n $holds_json ]]; then
    printf '%s\n' "$holds_json" > "$state_root/agent/holds.json"
  fi

  local exit_code=0
  set +e
  PATH="$tmp/bin:$PATH" \
    EVENTS="$events" \
    METADATA_JSON="$metadata" \
    REPO_URL=unused \
    TARGET_ATTR=unused \
    CACHE_BRANCH=cache-bump \
    KEEP_ROOTS=1 \
    EXCLUDED_PACKAGES='[]' \
    GITHUB_TOKEN_FILE="$token_file" \
    OMP_UPDATER="$tmp/bin/omp-updater" \
    WORKTREE="$worktree" \
    bash "$tmp/prebuild.sh" candidate > /dev/null 2>&1
  exit_code=$?
  set -e

  [[ $exit_code -eq 42 ]] || {
    printf 'expected build exit 42, got: %s\n' "$exit_code" >&2
    return 1
  }
  grep -qx build "$events" || {
    printf 'script did not reach nix build\n' >&2
    return 1
  }
}

assert_case() {
  local label=$1 holds_json=$2 expected=$3 actual
  run_case "$holds_json"
  actual=$(update_call)
  [[ $actual == "$expected" ]] || {
    printf '%s: expected %q, got %q\n' "$label" "$expected" "$actual" >&2
    exit 1
  }
}

assert_no_update() {
  local label=$1 holds_json=$2
  run_case "$holds_json"
  grep -q '^flake metadata' "$events" || {
    printf '%s: hold list was not consulted\n' "$label" >&2
    exit 1
  }
  ! grep -qE '^flake update( |$)' "$events" || {
    printf '%s: expected no flake update call, got %q\n' "$label" "$(<"$events")" >&2
    exit 1
  }
}

all_inputs="flake update --flake $worktree"
without_nixpkgs="$all_inputs home-manager oh-my-pi stylix"

assert_case 'no holds file' '' "$all_inputs"
assert_case 'empty hold object' '{}' "$all_inputs"
assert_case 'active hold (future)' "$(hold nixpkgs "$tomorrow")" "$without_nixpkgs"
assert_case 'active hold (today)' "$(hold nixpkgs "$today")" "$without_nixpkgs"
assert_case 'expired hold' "$(hold nixpkgs "$yesterday")" "$all_inputs"
assert_case 'unknown input held' "$(hold not-an-input "$tomorrow")" "$all_inputs"
assert_case 'malformed json' '{"nixpkgs": ' "$all_inputs"
assert_no_update 'every input held' "$(hold_all "$tomorrow")"
