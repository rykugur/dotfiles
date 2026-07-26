#!/usr/bin/env bash
set -Eeuo pipefail

repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)
script="$repo_root/scripts/vasher-promote.sh"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

make_repo() {
  local remote=$1 source=$2 checkout=$3
  git init --bare "$remote" >/dev/null
  git -C "$remote" symbolic-ref HEAD refs/heads/master
  git init "$source" >/dev/null
  git -C "$source" config user.name test
  git -C "$source" config user.email test@example.invalid
  mkdir -p "$source/scripts"
  cp "$script" "$source/scripts/vasher-promote.sh"
  chmod +x "$source/scripts/vasher-promote.sh"
  printf 'base\n' > "$source/file"
  git -C "$source" add file scripts/vasher-promote.sh
  git -C "$source" commit -m base >/dev/null
  git -C "$source" branch -M master
  git -C "$source" remote add origin "$remote"
  git -C "$source" push -u origin master >/dev/null
  git clone "$remote" "$checkout" >/dev/null
}

remote="$tmp/remote.git"
source="$tmp/source"
checkout="$tmp/checkout"
make_repo "$remote" "$source" "$checkout"

stub_bin="$tmp/bin"
mkdir "$stub_bin"
printf '#!/usr/bin/env bash\nexec "$@"\n' > "$stub_bin/sudo"
printf '#!/usr/bin/env bash\nprintf "%%s\\n" "$*" > "$NH_LOG"\n' > "$stub_bin/nh"
chmod +x "$stub_bin/sudo" "$stub_bin/nh"

assert_fails() {
  if PATH="$stub_bin:$PATH" NH_LOG="$tmp/nh.log" "$@"; then
    echo "expected command to fail: $*" >&2
    exit 1
  fi
}

printf 'candidate\n' > "$source/file"
git -C "$source" commit -am candidate >/dev/null
candidate=$(git -C "$source" rev-parse HEAD)
git -C "$source" push origin HEAD:cache-bump >/dev/null
git -C "$checkout" fetch origin cache-bump:refs/remotes/origin/cache-bump >/dev/null
base=$(git -C "$checkout" rev-parse master)

assert_no_effects() {
  test "$(git -C "$checkout" rev-parse master)" = "$base"
  test ! -e "$tmp/nh.log"
}

printf 'dirty\n' >> "$checkout/file"
assert_fails "$checkout/scripts/vasher-promote.sh"
assert_no_effects
git -C "$checkout" checkout -- file

git -C "$checkout" switch -c feature >/dev/null
assert_fails "$checkout/scripts/vasher-promote.sh"
assert_no_effects
git -C "$checkout" switch master >/dev/null

git -C "$source" push origin --delete cache-bump >/dev/null
assert_fails "$checkout/scripts/vasher-promote.sh"
assert_no_effects

git -C "$source" push origin HEAD:cache-bump >/dev/null
PATH="$stub_bin:$PATH" NH_LOG="$tmp/nh.log" "$checkout/scripts/vasher-promote.sh"
test "$(git -C "$checkout" rev-parse master)" = "$candidate"
test "$(git -C "$remote" rev-parse refs/heads/master)" = "$candidate"
test "$(cat "$tmp/nh.log")" = "os switch .#$(hostname)"
