#!/usr/bin/env bash
set -euo pipefail

module_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$module_dir/update-omp.sh"
tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

write_release() {
  local path="$1" draft="$2" prerelease="$3" omit_asset="${4:-}"
  jq -n \
    --argjson draft "$draft" \
    --argjson prerelease "$prerelease" \
    --arg omitted "$omit_asset" \
    '{tag_name:"v17.0.1", draft:$draft, prerelease:$prerelease,
      assets:[
        {name:"omp-linux-x64", digest:"sha256:427a8743b0b4ef701cc4a0c66bf1f0b91cec06280e8df62294a114e07fb38215"},
        {name:"omp-linux-arm64", digest:"sha256:8ce73061e02f6d4e07dfa14d0f593d0894987056f703b18c1b1518d561eea509"},
        {name:"omp-darwin-x64", digest:"sha256:1631a0ed8e2f734ce867bb44bcdba1fd6dceb35d8ab4c20a137629ebdcd6cb46"},
        {name:"omp-darwin-arm64", digest:"sha256:ef7bffcce5233a5a20a2c77bee17e0a58eee4d86a8cacc5e77d05a3cee954cf8"}
      ] | map(select(.name != $omitted))}' > "$path"
}
assert_rejected() {
  if normalize_release "$@" > "$tmpdir/unexpected-output.json"; then
    printf 'expected normalize_release to reject %s\n' "$1" >&2
    return 1
  fi
}


write_release "$tmpdir/stable.json" false false
normalize_release "$tmpdir/stable.json" 17.0.1 > "$tmpdir/lock.json"
jq -e '.version == "17.0.1" and .sources["x86_64-linux"].hash == "sha256-QnqHQ7C073AcxKDGa/HwuRzsBigOjfYilKEU4H+zghU="' "$tmpdir/lock.json"

write_release "$tmpdir/draft.json" true false
assert_rejected "$tmpdir/draft.json" 17.0.1
write_release "$tmpdir/pre.json" false true
assert_rejected "$tmpdir/pre.json" 17.0.1
write_release "$tmpdir/missing.json" false false omp-linux-arm64
assert_rejected "$tmpdir/missing.json" 17.0.1

write_release "$tmpdir/unstable-tag.json" false false
jq '.tag_name = "v17.0.1-rc.1"' "$tmpdir/unstable-tag.json" > "$tmpdir/unstable-tag.tmp"
mv "$tmpdir/unstable-tag.tmp" "$tmpdir/unstable-tag.json"
assert_rejected "$tmpdir/unstable-tag.json" 17.0.1

write_release "$tmpdir/requested-mismatch.json" false false
assert_rejected "$tmpdir/requested-mismatch.json" 17.0.2

write_release "$tmpdir/duplicate-asset.json" false false
jq '.assets += [.assets[0]]' "$tmpdir/duplicate-asset.json" > "$tmpdir/duplicate-asset.tmp"
mv "$tmpdir/duplicate-asset.tmp" "$tmpdir/duplicate-asset.json"
assert_rejected "$tmpdir/duplicate-asset.json" 17.0.1

write_release "$tmpdir/malformed-digest.json" false false
jq '(.assets[] | select(.name == "omp-linux-x64")).digest = "sha512:bad"' "$tmpdir/malformed-digest.json" > "$tmpdir/malformed-digest.tmp"
mv "$tmpdir/malformed-digest.tmp" "$tmpdir/malformed-digest.json"
assert_rejected "$tmpdir/malformed-digest.json" 17.0.1

printf '%s\n' '{"sentinel":true}' > "$tmpdir/existing.json"
! normalize_release "$tmpdir/draft.json" 17.0.1 > "$tmpdir/new.json"
jq -e '.sentinel == true' "$tmpdir/existing.json"
write_lock "$tmpdir/lock.json" "$tmpdir/existing.json"
jq -e '.version == "17.0.1"' "$tmpdir/existing.json"
