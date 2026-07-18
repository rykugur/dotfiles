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

bash_path="$(command -v bash)"
real_nix="$(command -v nix)"
real_mv="$(command -v mv)"
fake_bin="$tmpdir/fake-bin"
test_repo="$tmpdir/repo"
mkdir -p "$fake_bin" "$test_repo/modules/ai/oh-my-pi"

printf '#!%s\n' "$bash_path" > "$fake_bin/curl"
cat >> "$fake_bin/curl" <<'EOF'
set -euo pipefail
cat "$UPDATE_OMP_TEST_RELEASE"
EOF
chmod +x "$fake_bin/curl"

printf '#!%s\n' "$bash_path" > "$fake_bin/git"
cat >> "$fake_bin/git" <<'EOF'
set -euo pipefail
[[ "$#" -eq 4 && "$1" == -C && "$2" == "$UPDATE_OMP_TEST_REPO" && "$3" == rev-parse && "$4" == --show-toplevel ]] || exit 1
printf '%s\n' "$2"
EOF
chmod +x "$fake_bin/git"

printf '#!%s\n' "$bash_path" > "$fake_bin/nix"
cat >> "$fake_bin/nix" <<'EOF'
set -euo pipefail
if [[ "$1" == hash ]]; then
  exec "$REAL_NIX" "$@"
fi
[[ "$1" == build ]] || exit 1
if [[ "$EXPECT_NO_LINK" == true ]]; then
  [[ "$#" -eq 3 && "$2" == --no-link && "$3" == "$EXPECTED_NIX_TARGET" ]] || exit 1
fi
[[ ! -e "$PWD/result" ]] || exit 1
printf '%s\n' "$*" > "$NIX_BUILD_LOG"
EOF
chmod +x "$fake_bin/nix"

printf '#!%s\n' "$bash_path" > "$fake_bin/mv"
cat >> "$fake_bin/mv" <<'EOF'
set -euo pipefail
source="$1"
destination="$2"
[[ "$#" -eq 2 && "$destination" == "$EXPECTED_LOCK_PATH" ]] || exit 1
[[ "$(dirname "$source")" == "$(dirname "$destination")" ]] || exit 1
[[ "$source" == "$destination".tmp.* ]] || exit 1
printf '%s\n' "$source" > "$ATOMIC_RENAME_LOG"
exec "$REAL_MV" "$@"
EOF
chmod +x "$fake_bin/mv"

run_updater() {
  local release="$1" updater_tmpdir="$2" expect_no_link="${3:-false}"
  (
    cd "$test_repo"
    TMPDIR="$updater_tmpdir" \
      UPDATE_OMP_TEST_RELEASE="$release" \
      REAL_NIX="$real_nix" \
      REAL_MV="$real_mv" \
      UPDATE_OMP_TEST_REPO="$test_repo" \
      EXPECT_NO_LINK="$expect_no_link" \
      EXPECTED_NIX_TARGET="$test_repo#oh-my-pi" \
      EXPECTED_LOCK_PATH="$test_repo/modules/ai/oh-my-pi/release.json" \
      NIX_BUILD_LOG="$tmpdir/nix-build.log" \
      ATOMIC_RENAME_LOG="$tmpdir/atomic-rename.log" \
      PATH="$fake_bin:$PATH" \
      "$bash_path" "$module_dir/update-omp.sh" 17.0.1
  )
}

write_release "$tmpdir/cleanup-stable.json" false false
printf '%s\n' '{"version":"old"}' > "$test_repo/modules/ai/oh-my-pi/release.json"
injection_marker="$tmpdir/injection-marker"
unsafe_tmpdir="$tmpdir/unsafe'\$(touch \"\$INJECTION_MARKER\")'"
mkdir -p "$unsafe_tmpdir"
INJECTION_MARKER="$injection_marker" run_updater "$tmpdir/cleanup-stable.json" "$unsafe_tmpdir"
[[ ! -e "$injection_marker" ]] || {
  printf 'temporary path was parsed by the EXIT trap\n' >&2
  exit 1
}

safe_tmpdir="$tmpdir/safe"
mkdir -p "$safe_tmpdir"
printf '%s\n' '{"version":"sentinel"}' > "$test_repo/modules/ai/oh-my-pi/release.json"
cp "$test_repo/modules/ai/oh-my-pi/release.json" "$tmpdir/release-before-invalid.json"
rm -f "$tmpdir/nix-build.log" "$tmpdir/atomic-rename.log"
write_release "$tmpdir/invalid-for-main.json" true false
if run_updater "$tmpdir/invalid-for-main.json" "$safe_tmpdir" true; then
  printf 'invalid release metadata unexpectedly updated the lock\n' >&2
  exit 1
fi
cmp -s "$tmpdir/release-before-invalid.json" "$test_repo/modules/ai/oh-my-pi/release.json"
[[ ! -e "$tmpdir/nix-build.log" && ! -e "$tmpdir/atomic-rename.log" ]]

printf '%s\n' '{"version":"old"}' > "$test_repo/modules/ai/oh-my-pi/release.json"
rm -f "$tmpdir/nix-build.log" "$tmpdir/atomic-rename.log" "$test_repo/result"
run_updater "$tmpdir/cleanup-stable.json" "$safe_tmpdir" true
jq -e '.version == "17.0.1"' "$test_repo/modules/ai/oh-my-pi/release.json"
[[ ! -e "$test_repo/result" ]]
[[ -s "$tmpdir/nix-build.log" && -s "$tmpdir/atomic-rename.log" ]]
