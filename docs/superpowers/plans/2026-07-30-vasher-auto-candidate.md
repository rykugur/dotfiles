# Vasher Automatic Fresh Candidate Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Keep `cache-bump` automatically rebuilt from current `master` with fresh flake and OMP updates, so promotion stays fast-forward-only without manual candidate maintenance.

**Architecture:** Replace the existing periodic master build with a non-blocking freshness probe. The probe starts a serialized candidate build only when `cache-bump` no longer covers `origin/master`; a nightly forced run retains update cadence during quiet periods. The candidate records machine-readable lifecycle state and avoids publishing when its base is already obsolete at its final check. Promotion retains its ancestry safety check, so a candidate that becomes stale in the remaining fetch-to-push window is never promoted.

**Tech Stack:** NixOS modules, Bash, systemd timers/services, Git, Nix, jq.

## Global Constraints

- Preserve signed-cache-only use on Jezrien; do not add remote build delegation.
- Do not automate promotion or run any NixOS activation command.
- Do not add or run tests; the user explicitly removed them.
- Keep exactly one Vasher prebuild active through `/var/lib/vasher/prebuild.lock`.
- Preserve the reduced `nixosConfigurations.jezrien-prebuild` target and `bambu-studio` exclusion.

---

### Task 1: Model candidate freshness and lifecycle state

**Files:**
- Modify: `modules/nixos/vasher-prebuild.nix:19-97`

**Interfaces:**
- Consumes: `CACHE_BRANCH`, `TARGET_ATTR`, `EXCLUDED_PACKAGES`, and existing `/var/lib/vasher` paths.
- Produces: `/var/lib/vasher/last-build.json` with `state`, `mode`, `baseRevision`, `revision`, `output`, `excludedPackages`, and `exitCode` as applicable.

- [ ] **Step 1: Define status writers before acquiring the lock**

Add Bash helpers that atomically write a temporary JSON file and rename it to `/var/lib/vasher/last-build.json`:

```bash
write_status() {
  jq -n \
    --arg state "$1" --arg mode "$mode" --arg baseRevision "$base_revision" \
    --arg revision "$candidate_revision" --arg output "$out" \
    --argjson excludedPackages "$EXCLUDED_PACKAGES" \
    '{state:$state,mode:$mode,baseRevision:$baseRevision,revision:$revision,output:$output,excludedPackages:$excludedPackages}' \
    > "$status.tmp"
  mv "$status.tmp" "$status"
}
```

Initialize `base_revision`, `candidate_revision`, and `out` to empty strings. Extend the existing `ERR` trap to write `state:"failed"` and `exitCode` before exiting with the original status.

After capturing `base_revision`, write `state:"building"` immediately before a real candidate build begins. A `refresh` no-op writes `state:"idle"` with its current base revision; it never invokes Nix or the OMP updater.

- [ ] **Step 2: Fetch candidate metadata safely**

After fetching `origin/master`, attempt to fetch `cache-bump` into `refs/remotes/origin/$CACHE_BRANCH`. Treat an absent remote branch as an absent candidate, but do not hide a failed `origin/master` fetch. Capture the base revision once:

```bash
git -C "$repo" fetch origin master
git -C "$repo" fetch origin "$CACHE_BRANCH:refs/remotes/origin/$CACHE_BRANCH" || true
base_revision=$(git -C "$repo" rev-parse origin/master)
```

- [ ] **Step 3: Add `candidate_covers_base`**

Implement the predicate without inspecting commit messages:

```bash
candidate_covers_base() {
  git -C "$repo" show-ref --verify --quiet "refs/remotes/origin/$CACHE_BRANCH" &&
    git -C "$repo" merge-base --is-ancestor "$base_revision" "origin/$CACHE_BRANCH"
}
```

It is true only when the published candidate contains the captured `master` revision.

- [ ] **Step 4: Add an explicit refresh mode**

Accept `refresh` and `candidate` modes. `refresh` exits successfully with `state:"idle"` when `candidate_covers_base` is true. `candidate` always refreshes, for the nightly forced run. Both modes otherwise perform the existing worktree reset, `nix flake update`, OMP update, reduced closure build, GC-root retention, and `cache-bump` publication.

- [ ] **Step 5: Reject an obsolete build before publication**

Immediately after the reduced closure succeeds and before `git push`, fetch `origin/master` again. If it no longer equals `$base_revision`, write `state:"stale"`, leave `cache-bump` unchanged, and exit `0`:

```bash
git -C "$repo" fetch origin master
[[ $(git -C "$repo" rev-parse origin/master) == "$base_revision" ]] || {
  write_status stale
  exit 0
}
```

On publication success, set `candidate_revision` to `git -C "$worktree" rev-parse HEAD` and write `state:"success"`.

- [ ] **Step 6: Commit the lifecycle behavior**

```bash
git add modules/nixos/vasher-prebuild.nix
git commit -m "feat(vasher): refresh stale cache candidates"
```

### Task 2: Schedule automatic refreshes without overlapping builds

**Files:**
- Modify: `modules/nixos/vasher-prebuild.nix:99-176`

**Interfaces:**
- Consumes: `vasher-prebuild refresh` from Task 1.
- Produces: a 15-minute `vasher-prebuild-refresh` systemd service/timer and a nightly forced `vasher-prebuild-candidate` service/timer.

- [ ] **Step 1: Replace the master periodic builder service**

Define `vasher-prebuild-refresh` with `ExecStart = "${prebuild}/bin/vasher-prebuild refresh"`. Give it the current master service's non-blocking lock behavior: if another build owns the lock, it exits zero and the next timer run retries.

- [ ] **Step 2: Preserve the candidate service as a forced nightly refresh**

Keep `vasher-prebuild-candidate` as `vasher-prebuild candidate`; it uses the blocking lock and remains the once-nightly forced update path.

- [ ] **Step 3: Configure the refresh timer**

Replace `vasher-prebuild-master.timer` with `vasher-prebuild-refresh.timer`:

```nix
systemd.timers.vasher-prebuild-refresh = {
  wantedBy = [ "timers.target" ];
  timerConfig = {
    OnBootSec = "5m";
    OnUnitInactiveSec = "15m";
    Persistent = true;
  };
};
```

This naturally coalesces pushes during an active candidate: skipped probes retry on their next cadence without a queued job.

- [ ] **Step 4: Keep the nightly timer unchanged**

Retain `OnCalendar = "*-*-* 03:00:00"`, `Persistent = true`, and `RandomizedDelaySec = "10m"` for the forced candidate service.

- [ ] **Step 5: Commit the scheduling change**

```bash
git add modules/nixos/vasher-prebuild.nix
git commit -m "feat(vasher): schedule automatic candidate refreshes"
```

### Task 3: Make promotion report automatic refresh status

**Files:**
- Modify: `scripts/vasher-promote.sh:15-22`

**Interfaces:**
- Consumes: fetched `origin/cache-bump` and current local `master`.
- Produces: a successful fast-forward promotion only when the candidate contains local `master`; otherwise a non-destructive retry message.

- [ ] **Step 1: Preserve the ancestry guard**

Keep `git merge-base --is-ancestor HEAD origin/cache-bump`; it remains the proof that promotion does not combine a candidate with unbuilt `master` changes.

- [ ] **Step 2: Replace the remediation-oriented failure text**

Change only the failure message to:

```bash
git merge-base --is-ancestor HEAD origin/cache-bump ||
  fail "candidate for $(git rev-parse --short HEAD) is rebuilding or unavailable; retry after Vasher refreshes it"
```

Do not start services, wait, use SSH, or change local/remote branches on this path.

- [ ] **Step 3: Commit the operator-facing message**

```bash
git add scripts/vasher-promote.sh
git commit -m "feat(vasher): report automatic candidate refresh status"
```

### Task 4: Build and hand off the configuration

**Files:**
- No source changes.

**Interfaces:**
- Consumes: all prior commits.
- Produces: an evaluated Vasher NixOS system closure for the user to activate manually.

- [ ] **Step 1: Build the configured Vasher system**

```bash
nix build .#nixosConfigurations.vasher.config.system.build.toplevel --no-link
```

Expected: exit status `0`.

- [ ] **Step 2: Inspect the generated systemd service commands**

```bash
nix eval .#nixosConfigurations.vasher.config.systemd.services.vasher-prebuild-refresh.serviceConfig.ExecStart --raw
nix eval .#nixosConfigurations.vasher.config.systemd.services.vasher-prebuild-candidate.serviceConfig.ExecStart --raw
```

Expected: the first ends in `refresh`; the second ends in `candidate`.

- [ ] **Step 3: Push reviewed commits**

```bash
git push origin master
```

- [ ] **Step 4: Hand off activation to the user**

State the exact command but do not run it:

```bash
ssh root@vasher.local.ryk.sh 'nixos-rebuild switch --refresh --flake github:rykugur/dotfiles#vasher'
```

- [ ] **Step 5: Hand off operational verification to the user**

After activation, the user may inspect status and manually trigger a refresh:

```bash
ssh root@vasher.local.ryk.sh 'systemctl status vasher-prebuild-refresh.timer vasher-prebuild-candidate.timer --no-pager'
ssh root@vasher.local.ryk.sh 'systemctl start vasher-prebuild-refresh.service'
ssh root@vasher.local.ryk.sh 'cat /var/lib/vasher/last-build.json'
```
