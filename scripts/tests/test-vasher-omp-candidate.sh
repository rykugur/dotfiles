#!/usr/bin/env bash
set -Eeuo pipefail

repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)
service=$(nix eval "$repo_root#nixosConfigurations.vasher.config.systemd.services.vasher-prebuild-candidate.serviceConfig.ExecStart" --raw)
script=${service%% candidate}

deriver=$(nix eval --impure --json --expr "let f = builtins.getFlake \"git+file://$repo_root\"; in builtins.getContext f.nixosConfigurations.vasher.config.systemd.services.vasher-prebuild-candidate.serviceConfig.ExecStart" | jq -r 'keys[0]')
nix build --no-link "$deriver^out"
body=$(cat "$script")

update='update-omp.sh'
flake_update='nix flake update --flake "$worktree"'
closure_build='nix build "$worktree#$TARGET_ATTR" --no-link --print-out-paths'
stage='git -C "$worktree" add flake.lock modules/ai/oh-my-pi/release.json'
push_ref='HEAD:refs/heads/$CACHE_BRANCH'


[[ $body == *"$update"* ]]
[[ $body == *"$stage"* ]]
[[ $body == *"$push_ref"* ]]
(( $(grep -Fno "$flake_update" <<<"$body" | cut -d: -f1 | head -n1) < $(grep -Fno "$update" <<<"$body" | cut -d: -f1 | head -n1) ))
(( $(grep -Fno "$update" <<<"$body" | cut -d: -f1 | head -n1) < $(grep -Fno "$closure_build" <<<"$body" | cut -d: -f1 | head -n1) ))
