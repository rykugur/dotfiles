#!/usr/bin/env bash
set -Eeuo pipefail

mode=${1-}
expected_base=${2-}
expected_candidate=${3-}
state_dir=/var/lib/vasher/dashboard
status="$state_dir/status.json"
history="$state_dir/history.json"
log="$state_dir/log.txt"
raw_log="$state_dir/current.log"
legacy_status=/var/lib/vasher/last-build.json
HOLDS_FILE=/var/lib/vasher/agent/holds.json
base_revision=
candidate_revision=
out=
root_created=false
lock_acquired=false
started_at=$(date --iso-8601=seconds)

mkdir -p "$state_dir"
: > "$raw_log"
exec > >(tee -a "$raw_log") 2>&1

cleanup_tmp() {
  rm -f "$status_tmp" "$history_tmp" "$log_tmp" "$legacy_status_tmp"
}

snapshot_log() {
  tail -n 200 "$raw_log" > "$log_tmp"
  mv "$log_tmp" "$log"
}

append_history() {
  jq -cn --argjson entry "$1" --slurpfile old "$history" \
    '[$entry] + ($old[0] // []) | .[:20]' > "$history_tmp"
  mv "$history_tmp" "$history"
}

write_status() {
  local state=$1
  local exit_code=$2
  local updated_at payload

  updated_at=$(date --iso-8601=seconds)
  payload=$(jq -n \
    --arg state "$state" \
    --arg mode "$mode" \
    --arg startedAt "$started_at" \
    --arg updatedAt "$updated_at" \
    --arg baseRevision "$base_revision" \
    --arg revision "$candidate_revision" \
    --arg output "$out" \
    --argjson exitCode "$exit_code" \
    --argjson excludedPackages "$EXCLUDED_PACKAGES" \
    '{
      state: $state,
      mode: $mode,
      startedAt: $startedAt,
      updatedAt: $updatedAt,
      baseRevision: $baseRevision,
      revision: $revision,
      output: $output,
      excludedPackages: $excludedPackages
    } + if $exitCode == null then {} else { exitCode: $exitCode } end')

  jq -c . <<< "$payload" > "$status_tmp"
  mv "$status_tmp" "$status"
  jq -c . <<< "$payload" > "$legacy_status_tmp"
  mv "$legacy_status_tmp" "$legacy_status"
  snapshot_log

  if [[ $state =~ ^(success|failed|stale)$ ]]; then
    append_history "$payload"
  fi
}

record_failure() {
  local exit_code=$?
  trap - ERR
  ((BASH_SUBSHELL == 0)) || exit "$exit_code"
  [[ $lock_acquired == true ]] && write_status failed "$exit_code" || true
  [[ $lock_acquired == true ]] && nix-collect-garbage || true
  exit "$exit_code"
}
trap record_failure ERR

record_interruption() {
  local exit_code=$1
  trap - ERR INT TERM
  [[ $lock_acquired == true ]] && write_status failed "$exit_code" || true
  exit "$exit_code"
}
trap 'record_interruption 130' INT
trap 'record_interruption 143' TERM

status_tmp="$status.$$"
history_tmp="$history.$$"
log_tmp="$log.$$"
legacy_status_tmp="$legacy_status.$$"
trap cleanup_tmp EXIT

[[ -e $history ]] || printf '[]\n' > "$history"

exec 9>/var/lib/vasher/prebuild.lock
case $mode in
  refresh) flock -n 9 || exit 0; lock_acquired=true ;;
  candidate | retry | narrow) flock 9; lock_acquired=true ;;
  *) printf 'vasher-prebuild: unknown mode %s\n' "$mode" >&2; exit 2 ;;
esac

# A storage fault means the disk under the Nix store is suspect. Building again
# would only add writes, so the pipeline halts until an operator removes the
# file the monitor wrote; this script never removes it.
storage_fault=/var/lib/vasher/monitor/storage-fault.json
if [[ -e $storage_fault ]]; then
  printf 'vasher-prebuild: storage fault recorded in %s; refusing to build\n' \
    "$storage_fault" >&2
  write_status blocked null
  exit 0
fi

repo=/var/lib/vasher/repo
roots=/var/lib/vasher/gcroots
worktree=/var/lib/vasher/worktrees/"$mode"
[[ $mode == retry ]] && worktree=/var/lib/vasher/worktrees/candidate
mkdir -p "$roots"
[[ -d $repo/.git ]] || git clone "$REPO_URL" "$repo"

candidate_covers_base() {
  git -C "$repo" show-ref --verify --quiet "refs/remotes/origin/$CACHE_BRANCH" &&
    git -C "$repo" merge-base --is-ancestor "$base_revision" "origin/$CACHE_BRANCH"
}

prune_roots() {
  mapfile -t stale < <(ls -1t "$roots" | tail -n +$((KEEP_ROOTS + 1)))
  for root in "${stale[@]}"; do rm -f "$roots/$root"; done
}

validate_revision() {
  [[ $1 =~ ^[0-9a-f]{40}$ ]] || {
    printf 'vasher-prebuild: invalid revision: %s\n' "$1" >&2
    exit 2
  }
}

load_github_token() {
  [[ -s $GITHUB_TOKEN_FILE ]] || {
    printf 'vasher-prebuild: GitHub token is missing or empty\n' >&2
    exit 1
  }
  github_token=$(<"$GITHUB_TOKEN_FILE")
  nix_config="${NIX_CONFIG-}${NIX_CONFIG:+$'\n'}access-tokens = github.com=$github_token"
  unset github_token
}

# Prints the root flake inputs that no active hold covers, one per line.
# Prints nothing and returns 0 when the hold list is absent, unreadable,
# malformed, or holds nothing that the flake still declares: update everything.
# Returns 3 when every root input is held, which the caller cannot tell apart
# from the empty list: there is nothing left to update.
selected_inputs() {
  local today held metadata report total kept
  local -a lines
  [[ -r $HOLDS_FILE ]] || return 0
  today=$(date +%F)
  held=$(jq -c --arg today "$today" \
    '[to_entries[] | select((.value.expires // "") >= $today) | .key]' \
    "$HOLDS_FILE" 2> /dev/null) || return 0
  [[ -n $held && $held != '[]' ]] || return 0
  metadata=$(NIX_CONFIG="$nix_config" nix flake metadata --json --no-write-lock-file "$worktree" 2> /dev/null) || return 0
  report=$(jq -r --argjson held "$held" '
    .locks.nodes.root.inputs | keys as $all
    | ($all - $held) as $keep
    | ($all | length), ($keep | length), $keep[]
  ' <<< "$metadata" 2> /dev/null) || return 0
  mapfile -t lines <<< "$report"
  ((${#lines[@]} >= 2)) || return 0
  total=${lines[0]}
  kept=${lines[1]}
  if ((kept == total)); then return 0; fi
  if ((kept == 0)); then return 3; fi
  printf '%s\n' "${lines[@]:2}"
}

prepare_updated_candidate() {
  local -a update_inputs=()
  local selection= selection_status=0
  write_status preparing null
  nix-collect-garbage
  if [[ ! -e $worktree/.git ]]; then
    mkdir -p "$(dirname "$worktree")"
    git -C "$repo" worktree add --detach "$worktree" "$base_revision"
  fi
  git -C "$worktree" reset --hard "$base_revision"
  selection=$(selected_inputs) || selection_status=$?
  if ((selection_status == 3)); then
    printf 'vasher-prebuild: every flake input is held; skipping flake update\n'
  else
    [[ -z $selection ]] || mapfile -t update_inputs <<< "$selection"
    NIX_CONFIG="$nix_config" nix flake update --flake "$worktree" "${update_inputs[@]}"
  fi
  git -C "$worktree" add flake.lock
  if ! git -C "$worktree" diff --cached --quiet; then
    git -C "$worktree" -c user.name=vasher -c user.email=vasher@localhost \
      commit -m "chore: refreshed flake.lock ($(date -I))"
  fi
  candidate_revision=$(git -C "$worktree" rev-parse HEAD)
}

# Updates only the inputs the request names, after dropping the held ones.
# Unlike the candidate flow an empty selection is an error here: the caller
# asked for inputs that cannot be updated.
prepare_narrow_candidate() {
  local request=/var/lib/vasher/agent/narrow-request.json
  local inputs_text today held want metadata keep
  local -a requested=() update_inputs=()
  [[ -r $request ]] || {
    printf 'vasher-prebuild: narrow request %s is missing\n' "$request" >&2
    exit 2
  }
  base_revision=$(jq -er '.base // empty' "$request" 2> /dev/null) || {
    printf 'vasher-prebuild: narrow request has no base revision\n' >&2
    exit 2
  }
  inputs_text=$(jq -er '
    if (.inputs | type) != "array" then error("inputs must be an array")
    elif (.inputs | length) < 1 or (.inputs | length) > 8 then error("inputs must name 1 to 8 flake inputs")
    elif any(.inputs[]; type != "string") then error("input names must be strings")
    else .inputs[] end' "$request" 2> /dev/null) || {
    printf 'vasher-prebuild: narrow request has no usable input list\n' >&2
    exit 2
  }
  validate_revision "$base_revision"
  mapfile -t requested <<< "$inputs_text"

  git -C "$repo" fetch origin master
  [[ $(git -C "$repo" rev-parse origin/master) == "$base_revision" ]] || {
    printf 'vasher-prebuild: narrow base %s is not origin/master\n' "$base_revision" >&2
    return 1
  }
  load_github_token
  write_status preparing null
  nix-collect-garbage
  if [[ ! -e $worktree/.git ]]; then
    mkdir -p "$(dirname "$worktree")"
    git -C "$repo" worktree add --detach "$worktree" "$base_revision"
  fi
  git -C "$worktree" reset --hard "$base_revision"

  today=$(date +%F)
  held='[]'
  if [[ -r $HOLDS_FILE ]]; then
    held=$(jq -c --arg today "$today" \
      '[to_entries[] | select((.value.expires // "") >= $today) | .key]' \
      "$HOLDS_FILE" 2> /dev/null) || held='[]'
  fi
  want=$(jq -nc '$ARGS.positional' --args "${requested[@]}")
  metadata=$(NIX_CONFIG="$nix_config" nix flake metadata --json --no-write-lock-file "$worktree")
  keep=$(jq -r --argjson held "$held" --argjson want "$want" '
    (.locks.nodes.root.inputs | keys) as $all
    | ($want - $all) as $unknown
    | if ($unknown | length) > 0
      then error("unknown flake inputs: \($unknown | join(", "))")
      else ($want - $held | unique)[] end
  ' <<< "$metadata" 2> /dev/null) || {
    printf 'vasher-prebuild: narrow request names inputs this flake does not have\n' >&2
    return 1
  }
  [[ -n $keep ]] || {
    printf 'vasher-prebuild: every requested input is held\n' >&2
    return 1
  }
  mapfile -t update_inputs <<< "$keep"
  NIX_CONFIG="$nix_config" nix flake update --flake "$worktree" "${update_inputs[@]}"
  git -C "$worktree" add flake.lock
  if ! git -C "$worktree" diff --cached --quiet; then
    git -C "$worktree" -c user.name=vasher -c user.email=vasher@localhost \
      commit -m "chore: narrow flake.lock update: ${update_inputs[*]} ($(date -I))"
  fi
  candidate_revision=$(git -C "$worktree" rev-parse HEAD)
}

prepare_exact_retry() {
  validate_revision "$expected_base"
  validate_revision "$expected_candidate"
  base_revision=$expected_base
  candidate_revision=$expected_candidate
  [[ -e $worktree/.git ]] || {
    printf 'vasher-prebuild: retry worktree is missing\n' >&2
    exit 1
  }
  [[ $(git -C "$worktree" rev-parse HEAD) == "$candidate_revision" ]] || {
    printf 'vasher-prebuild: retry worktree does not match %s\n' "$candidate_revision" >&2
    exit 1
  }
  git -C "$worktree" merge-base --is-ancestor "$base_revision" "$candidate_revision"
  write_status preparing null
  nix-collect-garbage
}

if [[ $mode == retry ]]; then
  load_github_token
  prepare_exact_retry
elif [[ $mode == narrow ]]; then
  prepare_narrow_candidate
else
  git -C "$repo" fetch --prune origin
  base_revision=$(git -C "$repo" rev-parse origin/master)
  if [[ $mode == refresh ]] && candidate_covers_base; then
    write_status idle null
    exit 0
  fi
  load_github_token
  prepare_updated_candidate
fi

write_status building null
out=$(NIX_CONFIG="$nix_config" nix build "$worktree#$TARGET_ATTR" --no-link --print-out-paths)
unset nix_config

root_path="$roots/${out##*/}"
if [[ ! -e $root_path ]]; then
  nix-store --add-root "$root_path" --indirect --realise "$out"
  root_created=true
fi
touch -h "$root_path"

git -C "$repo" fetch origin master
if [[ $(git -C "$repo" rev-parse origin/master) != "$base_revision" ]]; then
  [[ $root_created == true ]] && rm -f "$root_path"
  prune_roots
  write_status stale null
  exit 0
fi

git -C "$worktree" push --force-with-lease origin "HEAD:refs/heads/$CACHE_BRANCH" || {
  git -C "$worktree" fetch origin "$CACHE_BRANCH:refs/remotes/origin/$CACHE_BRANCH"
  git -C "$worktree" push --force-with-lease origin "HEAD:refs/heads/$CACHE_BRANCH"
}
prune_roots
nix-collect-garbage
write_status success null
