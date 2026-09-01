# Vasher Garbage-Collection Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Recover Vasher and prevent failed candidate builds from filling its root disk with dead Nix store paths.

**Architecture:** Keep garbage collection inside the serialized prebuild workflow. Collect garbage before each update, after each recorded error, and after each successful candidate push.

**Tech Stack:** Bash, Nix, NixOS, systemd, Git, SSH.

## Global Constraints

- Preserve the original build exit code and dashboard log after an error.
- Keep the latest successful Jezrien closure protected by its GC root.
- Do not change timers, package exclusions, build concurrency, or root retention.
- Use the existing prebuild lock for all garbage collection.

---

### Task 1: Add workflow-local garbage collection

**Files:**
- Modify: `modules/nixos/vasher-prebuild.sh:75-80,124-143`

**Interfaces:**
- Consumes: the existing prebuild lock, `write_status`, and `nix-collect-garbage`.
- Produces: prebuild cleanup and best-effort error cleanup with the original exit code.

- [ ] **Step 1: Record the failing behavior**

Run:

```bash
ssh root@vasher 'df -h /; nix store gc --dry-run'
```

Expected: the root filesystem is 97% full, and Nix reports 30,011 dead store paths.
This is the existing failing reproduction from the 2026-08-31 candidate.

- [ ] **Step 2: Add cleanup after a recorded error**

Change `record_failure` to:

```bash
record_failure() {
  local exit_code=$?
  trap - ERR
  [[ $lock_acquired == true ]] && write_status failed "$exit_code" || true
  [[ $lock_acquired == true ]] && nix-collect-garbage || true
  exit "$exit_code"
}
```

The status call copies the error log before garbage-collection output occurs.
The disabled `ERR` trap and `|| true` preserve the original error.

- [ ] **Step 3: Add cleanup before update and build work**

Insert this command after `write_status building null` and before worktree update operations:

```bash
nix-collect-garbage
```

The process already owns the prebuild lock at this point.

- [ ] **Step 4: Make sure that the Bash syntax is valid**

Run:

```bash
bash -n modules/nixos/vasher-prebuild.sh
```

Expected: exit code `0` and no output.

- [ ] **Step 5: Build the generated prebuild application**

Run:

```bash
service=$(nix eval .#nixosConfigurations.vasher.config.systemd.services.vasher-prebuild-candidate.serviceConfig.ExecStart --raw)
nix build --no-link "${service% candidate}"
```

Expected: Nix builds the generated `vasher-prebuild` application without an evaluation or build error.

- [ ] **Step 6: Commit the workflow change**

```bash
git add modules/nixos/vasher-prebuild.sh
git commit -m "fix(vasher): collect garbage around prebuilds"
```

---

### Task 2: Recover and verify live Vasher

**Files:**
- No repository file changes.

**Interfaces:**
- Consumes: the committed workflow change and the `root@vasher` SSH target.
- Produces: a deployed service, available disk space, and a successful `cache-bump` candidate.

- [ ] **Step 1: Publish the approved commits**

Run:

```bash
git push origin master
```

Expected: `origin/master` advances through the design and workflow commits.

- [ ] **Step 2: Remove the current dead store paths**

Run:

```bash
ssh root@vasher nix-collect-garbage
ssh root@vasher df -h /
```

Expected: garbage collection exits `0`, and available root space increases from 3.7 GiB.
Nix keeps the current system and retained Jezrien closure because both have GC roots.

- [ ] **Step 3: Deploy the changed Vasher service**

Run:

```bash
ssh root@vasher 'nixos-rebuild switch --refresh --flake github:rykugur/dotfiles#vasher'
```

Expected: the switch exits `0` and does not start a candidate build.

- [ ] **Step 4: Start the candidate build**

Run:

```bash
ssh root@vasher 'systemctl start --no-block vasher-prebuild-candidate.service'
```

Expected: the SSH command exits `0` while the candidate service continues.

- [ ] **Step 5: Observe the prebuild cleanup**

Run:

```bash
ssh root@vasher 'journalctl -u vasher-prebuild-candidate.service -n 40 --no-pager -o cat'
```

Expected: the journal shows garbage collection before lock-file update and build output.

- [ ] **Step 6: Make sure that the candidate succeeds**

After the service stops, run:

```bash
ssh root@vasher 'systemctl is-failed vasher-prebuild-candidate.service; cat /var/lib/vasher/dashboard/status.json; df -h /'
git fetch --prune origin
git merge-base --is-ancestor origin/master origin/cache-bump
```

Expected:

- `systemctl is-failed` reports `inactive`, not `failed`.
- `status.json` reports `"state":"success"`.
- Available disk space remains higher than the initial 3.7 GiB.
- `origin/cache-bump` contains `origin/master`.

- [ ] **Step 7: Inspect cleanup after an unexpected build error**

If the candidate fails for an unrelated package, run:

```bash
ssh root@vasher 'cat /var/lib/vasher/dashboard/status.json; nix store gc --dry-run; df -h /'
```

Expected: the status keeps the original nonzero exit code and Nix reports no partial candidate closure left as dead paths.
