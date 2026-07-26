# Vasher Cache-Bump Promotion Script Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Provide one guarded command that promotes `cache-bump` into local `master`, pushes it, and switches the currently running NixOS host.

**Architecture:** A single Bash script resolves the repository root from its own path and fails before any mutation unless the resolved checkout is clean and on `master`. A disposable Git fixture exercises the script against local bare remotes; it replaces `sudo` and `nh` with controlled stubs so no real host rebuild runs during verification.

**Tech Stack:** Bash, Git, `nh`, disposable local Git repositories.

## Global Constraints

- Create executable `scripts/vasher-promote.sh`.
- Resolve repository root from the script location; never rely on caller working directory.
- Require a clean `master` checkout before mutation.
- Fetch `origin`, fast-forward only to `origin/cache-bump`, then push `master`.
- Never stash, reset, force-push, merge divergent history, or retry.
- Derive the NixOS target from `hostname`; do not accept or hard-code a host name.
- Run `sudo nh os switch .#<running-hostname>` only after the Git promotion succeeds.
- Tests must not contact a real remote or rebuild/switch a real host.

---

### Task 1: Guarded promotion script and disposable integration verification

**Files:**
- Create: `scripts/vasher-promote.sh`
- Create: `scripts/tests/test-vasher-promote.sh`

**Interfaces:**
- Consumes: the local checkout's `origin`, `master`, `origin/cache-bump`, `hostname`, `sudo`, and `nh` executables.
- Produces: `scripts/vasher-promote.sh`, which exits nonzero before mutation on failed checks and invokes `sudo nh os switch .#$(hostname)` only after successful Git promotion.

- [ ] **Step 1: Write the disposable integration test**

Create `scripts/tests/test-vasher-promote.sh`:

```bash
#!/usr/bin/env bash
set -Eeuo pipefail

repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)
script="$repo_root/scripts/vasher-promote.sh"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

make_repo() {
  local remote=$1 source=$2 checkout=$3
  git init --bare "$remote" >/dev/null
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
printf '#!/usr/bin/env bash\nprintf "%s\\n" "$*" > "$NH_LOG"\n' > "$stub_bin/nh"
chmod +x "$stub_bin/sudo" "$stub_bin/nh"

assert_fails() {
  if PATH="$stub_bin:$PATH" NH_LOG="$tmp/nh.log" "$@"; then
    echo "expected command to fail: $*" >&2
    exit 1
  fi
}

printf 'dirty\n' >> "$checkout/file"
assert_fails "$checkout/scripts/vasher-promote.sh"
git -C "$checkout" checkout -- file

git -C "$checkout" switch -c feature >/dev/null
assert_fails "$checkout/scripts/vasher-promote.sh"
git -C "$checkout" switch master >/dev/null

printf 'candidate\n' > "$source/file"
git -C "$source" commit -am candidate >/dev/null
git -C "$source" push origin HEAD:cache-bump >/dev/null
PATH="$stub_bin:$PATH" NH_LOG="$tmp/nh.log" "$checkout/scripts/vasher-promote.sh"
test "$(git -C "$checkout" rev-parse master)" = "$(git -C "$checkout" rev-parse origin/cache-bump)"
test "$(cat "$tmp/nh.log")" = "os switch .#$(hostname)"
```

- [ ] **Step 2: Run the test to verify it fails**

Run:

```bash
bash scripts/tests/test-vasher-promote.sh
```
Expected: FAIL because the script file cannot yet be copied into the disposable fixture.

- [ ] **Step 3: Implement the guarded script**

Create `scripts/vasher-promote.sh`:

```bash
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
```

- [ ] **Step 4: Run the integration test to verify it passes**

Run:

```bash
bash scripts/tests/test-vasher-promote.sh
```

Expected: exit 0; dirty and non-`master` cases fail as expected; valid promotion fast-forwards local `master`, and stubbed `nh` receives `os switch .#$(hostname)`.

- [ ] **Step 5: Check shell syntax and commit**

Run:

```bash
bash -n scripts/vasher-promote.sh scripts/tests/test-vasher-promote.sh
git add scripts/vasher-promote.sh scripts/tests/test-vasher-promote.sh
git commit -m "feat: add Vasher cache promotion script"
```
