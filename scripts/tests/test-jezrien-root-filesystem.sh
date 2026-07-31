#!/usr/bin/env bash
set -Eeuo pipefail

repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)
file_systems=$(nix eval "$repo_root#nixosConfigurations.jezrien.config.fileSystems" --json)

for mount_point in / /home /nix; do
  device=$(jq -r --arg mount_point "$mount_point" '.[$mount_point].device' <<<"$file_systems")
  [[ $device == /dev/disk/by-uuid/* ]] || {
    printf 'filesystem %s must use a stable UUID, got %s\n' "$mount_point" "$device" >&2
    exit 1
  }
done
