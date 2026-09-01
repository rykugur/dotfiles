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
- Create: `scripts/tests/test-vasher-prebuild-gc.sh`
- Modify: `modules/nixos/vasher-prebuild.sh:75-80,124-143`

**Interfaces:**
- Consumes: the existing prebuild lock, `write_status`, and `nix-collect-garbage`.
- Produces: prebuild cleanup and best-effort error cleanup with the original exit code.

- [ ] **Step 1: Write the failing regression test**

Create `scripts/tests/test-vasher-prebuild-gc.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

state_root=$tmp/state
events=$tmp/events
mkdir -p "$state_root/repo/.git" "$state_root/worktrees/candidate/.git" "$tmp/bin"

cat > "$tmp/bin/git" <<'EOF'
#!/usr/bin/env bash
if [[ $* == *"rev-parse origin/master"* ]]; then
  printf 'base\n'
fi
EOF

cat > "$tmp/bin/nix" <<'EOF'
#!/usr/bin/env bash
if [[ ${1-} == build ]]; then
  printf 'build\n' >> "$EVENTS"
  exit 42
fi
EOF

cat > "$tmp/bin/nix-collect-garbage" <<'EOF'
#!/usr/bin/env bash
printf 'gc\n' >> "$EVENTS"
EOF

cat > "$tmp/bin/omp-updater" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF

chmod +x "$tmp/bin/"*
source_text=$(<"$repo_root/modules/nixos/vasher-prebuild.sh")
printf '%s\n' "${source_text//\/var\/lib\/vasher/$state_root}" > "$tmp/prebuild.sh"

set +e
PATH="$tmp/bin:$PATH" \
  EVENTS="$events" \
  REPO_URL=unused \
  TARGET_ATTR=unused \
  CACHE_BRANCH=cache-bump \
  KEEP_ROOTS=1 \
  EXCLUDED_PACKAGES='[]' \
  OMP_UPDATER="$tmp/bin/omp-updater" \
  bash "$tmp/prebuild.sh" candidate
exit_code=$?
set -e

[[ $exit_code -eq 42 ]]
actual_events=$(<"$events")
[[ $actual_events == $'gc\nbuild\ngc' ]] || {
  printf 'expected cleanup/build/cleanup, got: %q\n' "$actual_events" >&2
  exit 1
}
jq -e '.state == "failed" and .exitCode == 42' "$state_root/dashboard/status.json" >/dev/null
```

- [ ] **Step 2: Run the test and observe the missing cleanup**

Run:

```bash
bash scripts/tests/test-vasher-prebuild-gc.sh
```

Expected: the event-order assertion fails because the current script records only `build`.

- [ ] **Step 3: Add cleanup after a recorded error**

Change `record_failure` to:

```bash
record_failure() {
  local exit_code=$?
  trap - ERR
  ((BASH_SUBSHELL == 0)) || exit "$exit_code"
  [[ $lock_acquired == true ]] && write_status failed "$exit_code" || true
  [[ $lock_acquired == true ]] && nix-collect-garbage || true
  exit "$exit_code"
}
```

The status call copies the error log before garbage-collection output occurs.
The disabled `ERR` trap and `|| true` preserve the original error.

- [ ] **Step 4: Add cleanup before update and build work**

Insert this command after `write_status building null` and before worktree update operations:

```bash
nix-collect-garbage
```

The process already owns the prebuild lock at this point.

- [ ] **Step 5: Run the regression test**

Run:

```bash
bash scripts/tests/test-vasher-prebuild-gc.sh
```

Expected: exit code `0`.
The test observes `gc`, `build`, and `gc` in that order.
The final status keeps the simulated build exit code `42`.

- [ ] **Step 6: Make sure that the Bash syntax is valid**

Run:

```bash
bash -n modules/nixos/vasher-prebuild.sh
bash -n scripts/tests/test-vasher-prebuild-gc.sh
```

Expected: exit code `0` and no output.

- [ ] **Step 7: Build the Vasher system closure**

Run:

```bash
nix build --no-link .#nixosConfigurations.vasher.config.system.build.toplevel
```

Expected: Nix builds the generated prebuild application and the Vasher system closure.

- [ ] **Step 8: Commit the workflow change**

```bash
git add docs/superpowers/plans/2026-08-31-vasher-garbage-collection.md docs/superpowers/specs/2026-08-31-vasher-garbage-collection-design.md modules/nixos/vasher-prebuild.sh scripts/tests/test-vasher-prebuild-gc.sh
git commit -m "fix(vasher): collect garbage around prebuilds"
```

---

### Task 2: Authenticate GitHub flake updates

**Files:**
- Modify: `modules/nixos/vasher-prebuild.nix:35-42,94-100`
- Modify: `modules/nixos/vasher-prebuild.sh:137-143`
- Modify: `scripts/tests/test-vasher-prebuild-gc.sh`

**Interfaces:**
- Consumes: the SOPS key `swoleflake/github_token`.
- Produces: runtime-only Nix `access-tokens` configuration for public GitHub flake inputs.

- [ ] **Step 1: Add the failing token regression**

In the fake `nix` command, reject calls that do not contain the test token:

```bash
if [[ ${NIX_CONFIG-} != *'access-tokens = github.com=test-token'* ]]; then
  printf 'missing GitHub access token\n' >&2
  exit 99
fi
```

Create a test token file:

```bash
token_file=$tmp/github-token
printf 'test-token\n' > "$token_file"
```

Pass its path to the prebuild:

```bash
GITHUB_TOKEN_FILE="$token_file" \
```

- [ ] **Step 2: Run the test and observe missing authentication**

Run:

```bash
bash scripts/tests/test-vasher-prebuild-gc.sh
```

Expected: the fake `nix` command reports `missing GitHub access token`.

- [ ] **Step 3: Declare the SOPS secret and wrapper path**

Add this secret beside the existing deploy-key secret:

```nix
sops.secrets."swoleflake/github_token" = {
  owner = "vasher";
  group = "vasher";
  mode = "0400";
};
```

Add this wrapper export beside the existing prebuild exports:

```nix
export GITHUB_TOKEN_FILE=${lib.escapeShellArg config.sops.secrets."swoleflake/github_token".path}
```

- [ ] **Step 4: Configure authenticated Nix commands**

Immediately before `nix flake update`, add:

```bash
github_token=$(<"$GITHUB_TOKEN_FILE")
if [[ -z $github_token ]]; then
  printf 'vasher-prebuild: GitHub token is empty\n' >&2
  exit 1
fi
nix_config="${NIX_CONFIG-}${NIX_CONFIG:+$'\n'}access-tokens = github.com=$github_token"
unset github_token
```

Pass `NIX_CONFIG="$nix_config"` to `nix flake update`, the OMP updater, and `nix build`.
Unset `nix_config` after the build command.

- [ ] **Step 5: Run the token and cleanup regression**

Run:

```bash
bash scripts/tests/test-vasher-prebuild-gc.sh
```

Expected: exit code `0`.
The fake Nix commands receive the test token.
The cleanup ordering and original exit code remain unchanged.

- [ ] **Step 6: Build the Vasher system closure**

Run:

```bash
nix build --no-link .#nixosConfigurations.vasher.config.system.build.toplevel
```

Expected: the secret declaration and generated service build without an evaluation error.

- [ ] **Step 7: Commit the authentication wiring**

```bash
git add docs/superpowers/plans/2026-08-31-vasher-garbage-collection.md modules/nixos/vasher-prebuild.nix modules/nixos/vasher-prebuild.sh scripts/tests/test-vasher-prebuild-gc.sh
git commit -m "fix(vasher): authenticate GitHub flake updates"
```

---

### Task 3: Recover and verify live Vasher

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
