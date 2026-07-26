#!/usr/bin/env bash
set -Eeuo pipefail

repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
cd "$repo_root"

fail() {
  printf 'vasher-promote: %s\n' "$*" >&2
  exit 1
}

[[ $(git branch --show-current) == master ]] || fail 'checkout must be on master'
[[ -z $(git status --porcelain) ]] || fail 'checkout must be clean'

printf '%s\n' 'Fetching origin...'
git fetch origin

git rev-parse --verify --quiet origin/cache-bump >/dev/null || fail 'origin/cache-bump does not exist'
git merge-base --is-ancestor HEAD origin/cache-bump || fail 'origin/cache-bump cannot fast-forward master'

printf '%s\n' 'Fast-forwarding master to cache-bump...'
git merge --ff-only origin/cache-bump

printf '%s\n' 'Pushing master...'
git push origin master

host=$(hostname)
printf 'Switching NixOS host %s...\n' "$host"
sudo nh os switch ".#$host"
