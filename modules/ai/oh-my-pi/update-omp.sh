#!/usr/bin/env bash
set -euo pipefail

readonly api_base='https://api.github.com/repos/can1357/oh-my-pi/releases'
readonly systems=(x86_64-linux aarch64-linux x86_64-darwin aarch64-darwin)
readonly assets=(omp-linux-x64 omp-linux-arm64 omp-darwin-x64 omp-darwin-arm64)

temporary_paths=()

cleanup_temporary_paths() {
  rm -f -- "${temporary_paths[@]}"
}


sri_hash() {
  nix hash convert --hash-algo sha256 --to sri "$1"
}

normalize_release() {
  local release_json="$1" requested_version="${2:-}"
  jq -e '
    (.draft | not) and (.prerelease | not) and
    (.tag_name | test("^v[0-9]+\\.[0-9]+\\.[0-9]+$"))
  ' "$release_json" >/dev/null || return 1

  local version
  version="$(jq -er '.tag_name | ltrimstr("v")' "$release_json")" || return 1
  [[ -z "$requested_version" || "$version" == "$requested_version" ]] || return 1

  local hashes=()
  local asset digest sri
  for asset in "${assets[@]}"; do
    digest="$(jq -er --arg asset "$asset" '[.assets[] | select(.name == $asset) | .digest] | if length == 1 then .[0] else error("expected exactly one asset") end' "$release_json")" || return 1
    [[ "$digest" =~ ^sha256:[0-9a-f]{64}$ ]] || return 1
    sri="$(sri_hash "${digest#sha256:}")" || return 1
    hashes+=("$sri")
  done

  jq -n \
    --arg version "$version" \
    --arg linux_x64 "${hashes[0]}" --arg linux_arm64 "${hashes[1]}" \
    --arg darwin_x64 "${hashes[2]}" --arg darwin_arm64 "${hashes[3]}" \
    '{version:$version,sources:{
      "x86_64-linux":{asset:"omp-linux-x64",hash:$linux_x64},
      "aarch64-linux":{asset:"omp-linux-arm64",hash:$linux_arm64},
      "x86_64-darwin":{asset:"omp-darwin-x64",hash:$darwin_x64},
      "aarch64-darwin":{asset:"omp-darwin-arm64",hash:$darwin_arm64}}}'
}

write_lock() {
  local source="$1" destination="$2" tmp
  tmp="$(mktemp "${destination}.tmp.XXXXXX")"
  trap 'rm -f "$tmp"' RETURN
  cp "$source" "$tmp"
  mv "$tmp" "$destination"
  trap - RETURN
}

main() {
  local requested_version="${1:-}" repo_root release_json lock_json old_version endpoint
  [[ $# -le 1 ]] || { echo "usage: update-oh-my-pi [VERSION]" >&2; return 2; }
  [[ -z "$requested_version" || "$requested_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || return 2

  repo_root="$(git -C "$PWD" rev-parse --show-toplevel)"
  [[ -f "$repo_root/modules/ai/oh-my-pi/release.json" ]] || return 1
  lock_json="$repo_root/modules/ai/oh-my-pi/release.json"
  old_version="$(jq -er '.version' "$lock_json")"
  endpoint="$api_base/latest"
  [[ -z "$requested_version" ]] || endpoint="$api_base/tags/v$requested_version"

  release_json="$(mktemp)"
  temporary_paths=("$release_json" "${release_json}.lock")
  trap cleanup_temporary_paths EXIT
  curl --fail --location --silent --show-error "$endpoint" > "$release_json"
  normalize_release "$release_json" "$requested_version" > "${release_json}.lock"
  write_lock "${release_json}.lock" "$lock_json"
  nix build --no-link "$repo_root#oh-my-pi"
  printf 'Updated OMP %s -> %s\n' "$old_version" "$(jq -er '.version' "$lock_json")"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
