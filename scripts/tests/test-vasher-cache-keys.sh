#!/usr/bin/env bash
set -Eeuo pipefail

repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)

mapfile -t keys < <(
  nix eval "$repo_root#nixosConfigurations.vasher.config.nix.settings.trusted-public-keys" --json \
    | jq -r '.[]'
)

for key in "${keys[@]}"; do
  payload=${key#*:}
  if ! bytes=$(printf '%s' "$payload" | base64 --decode 2>/dev/null | wc -c); then
    printf 'invalid Nix cache public key encoding: %s\n' "$key" >&2
    exit 1
  fi
  test "$bytes" -eq 32 || {
    printf 'invalid Nix cache public key: %s (decoded length: %s)\n' "$key" "$bytes" >&2
    exit 1
  }
done
