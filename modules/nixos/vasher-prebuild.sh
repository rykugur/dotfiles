#!/usr/bin/env bash
set -Eeuo pipefail

mode=$1
state_dir=/var/lib/vasher/dashboard
status="$state_dir/status.json"
history="$state_dir/history.json"
log="$state_dir/log.txt"
raw_log="$state_dir/current.log"
legacy_status=/var/lib/vasher/last-build.json
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
  candidate) flock 9; lock_acquired=true ;;
  *) printf 'vasher-prebuild: unknown mode %s\n' "$mode" >&2; exit 2 ;;
esac

repo=/var/lib/vasher/repo
roots=/var/lib/vasher/gcroots
mkdir -p "$roots"
[[ -d $repo/.git ]] || git clone "$REPO_URL" "$repo"
git -C "$repo" fetch --prune origin
base_revision=$(git -C "$repo" rev-parse origin/master)

candidate_covers_base() {
  git -C "$repo" show-ref --verify --quiet "refs/remotes/origin/$CACHE_BRANCH" &&
    git -C "$repo" merge-base --is-ancestor "$base_revision" "origin/$CACHE_BRANCH"
}

prune_roots() {
  mapfile -t stale < <(ls -1t "$roots" | tail -n +$((KEEP_ROOTS + 1)))
  for root in "${stale[@]}"; do rm -f "$roots/$root"; done
}

if [[ $mode == refresh ]] && candidate_covers_base; then
  write_status idle null
  exit 0
fi

write_status building null
nix-collect-garbage
worktree=/var/lib/vasher/worktrees/"$mode"
if [[ ! -e $worktree/.git ]]; then
  mkdir -p "$(dirname "$worktree")"
  git -C "$repo" worktree add --detach "$worktree" "$base_revision"
fi
git -C "$worktree" reset --hard "$base_revision"

if [[ ! -s $GITHUB_TOKEN_FILE ]]; then
  printf 'vasher-prebuild: GitHub token is missing or empty\n' >&2
  exit 1
fi
github_token=$(<"$GITHUB_TOKEN_FILE")
nix_config="${NIX_CONFIG-}${NIX_CONFIG:+$'\n'}access-tokens = github.com=$github_token"
unset github_token

NIX_CONFIG="$nix_config" nix flake update --flake "$worktree"
(
  cd "$worktree"
  NIX_CONFIG="$nix_config" bash "$OMP_UPDATER"
)

out=$(NIX_CONFIG="$nix_config" nix build "$worktree#$TARGET_ATTR" --no-link --print-out-paths)
unset nix_config
git -C "$worktree" add flake.lock modules/ai/oh-my-pi/release.json
if ! git -C "$worktree" diff --cached --quiet; then
  git -C "$worktree" -c user.name=vasher -c user.email=vasher@localhost \
    commit -m "chore: refreshed flake.lock and OMP update ($(date -I))"
fi
candidate_revision=$(git -C "$worktree" rev-parse HEAD)

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
