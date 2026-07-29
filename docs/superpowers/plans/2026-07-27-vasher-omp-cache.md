# Vasher OMP Candidate Cache Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Update OMP during Vasher's nightly candidate, validate it as part of Jezrien's reduced closure, and promote its release metadata with the candidate lock update.

**Architecture:** Extend only the candidate branch of `vasher-prebuild`. It runs the existing OMP release updater from the candidate worktree after `nix flake update`; the updater validates release metadata and builds `.#oh-my-pi`, then the existing reduced Jezrien closure build validates the deployed integration. The existing signed Harmonia cache, retention, cache-bump branch, and promotion script remain the sole delivery path.

**Tech Stack:** NixOS modules, Bash, systemd, Nix flakes, jq.

## Global Constraints

- Run OMP updates only from `vasher-prebuild-candidate`; never from the 15-minute `vasher-prebuild-master` job.
- Run the updater after `nix flake update` and before building `nixosConfigurations.jezrien-prebuild.config.system.build.toplevel`.
- Stage `flake.lock` and `modules/ai/oh-my-pi/release.json` together; publish `cache-bump` only after the full reduced closure succeeds.
- Preserve `--force-with-lease` for the disposable `cache-bump` ref; never force-push `master`.
- Preserve serialized scheduling, Bambu Studio exclusion, cache keys, retention, and all existing promotion semantics.
- Do not add timers, cache keys, branches, remote-builder configuration, or automatic promotion.

---

## File structure

- `modules/nixos/vasher-prebuild.nix`: candidate-only OMP update invocation and combined candidate staging.
- `scripts/tests/test-vasher-omp-candidate.sh`: regression test for the generated candidate prebuild command and its ordering.
- `wiki/hosts.md`: operator-facing statement that the nightly candidate advances OMP as part of the existing combined proposal.

### Task 1: Run and publish the OMP update with each candidate

**Files:**
- Modify: `modules/nixos/vasher-prebuild.nix:9-17,58-69`
- Create: `scripts/tests/test-vasher-omp-candidate.sh`

**Interfaces:**
- Consumes: `modules/ai/oh-my-pi/update-omp.sh`, which requires its working directory to be a dotfiles Git checkout and rewrites `modules/ai/oh-my-pi/release.json` only after stable-release/digest validation.
- Produces: a successful candidate commit containing both `flake.lock` and `modules/ai/oh-my-pi/release.json`; the existing `last-build.json`, GC-root, cache publishing, and `cache-bump` behavior are unchanged.

- [ ] **Step 1: Write the failing candidate-wiring regression test**

Create `scripts/tests/test-vasher-omp-candidate.sh`:

```bash
#!/usr/bin/env bash
set -Eeuo pipefail

repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)
service=$(nix eval "$repo_root#nixosConfigurations.vasher.config.systemd.services.vasher-prebuild-candidate.serviceConfig.ExecStart" --raw)
script=${service%% candidate}

nix build --no-link "$script"
body=$(cat "$script")

update='update-omp.sh'
flake_update='nix flake update --flake "$worktree"'
closure_build='nix build "$worktree#$TARGET_ATTR" --no-link --print-out-paths'
stage='git -C "$worktree" add flake.lock modules/ai/oh-my-pi/release.json'

[[ $body == *"$update"* ]]
[[ $body == *"$stage"* ]]
(( $(grep -Fno "$flake_update" <<<"$body" | cut -d: -f1 | head -n1) < $(grep -Fno "$update" <<<"$body" | cut -d: -f1 | head -n1) ))
(( $(grep -Fno "$update" <<<"$body" | cut -d: -f1 | head -n1) < $(grep -Fno "$closure_build" <<<"$body" | cut -d: -f1 | head -n1) ))
```

The Nix path interpolation makes the updater a store path whose basename remains `update-omp.sh`. The service `ExecStart` ends in ` candidate`; strip that suffix to obtain the generated `writeShellApplication` executable. The test must fail before implementation because the executable has no OMP updater call or combined staging command.

- [ ] **Step 2: Run the new test and confirm the red state**

Run:

```bash
bash scripts/tests/test-vasher-omp-candidate.sh
```

Expected: nonzero exit after the generated candidate body lacks `update-omp.sh`.

- [ ] **Step 3: Add the candidate-only updater call and combined staging**

In `modules/nixos/vasher-prebuild.nix`, add `curl` to `runtimeInputs` because `update-omp.sh` calls it directly:

```nix
runtimeInputs = with pkgs; [
  bash
  coreutils
  curl
  git
  jq
  nix
  openssh
  util-linux
];
```

Replace the candidate block and its staging line with:

```bash
if [[ $mode == candidate ]]; then
  nix flake update --flake "$worktree"
  (
    cd "$worktree"
    ${pkgs.bash}/bin/bash ${../ai/oh-my-pi/update-omp.sh}
  )
fi

out=$(nix build "$worktree#$TARGET_ATTR" --no-link --print-out-paths)
if [[ $mode == candidate ]]; then
  git -C "$worktree" add flake.lock modules/ai/oh-my-pi/release.json
  if ! git -C "$worktree" diff --cached --quiet; then
    git -C "$worktree" -c user.name=vasher -c user.email=vasher@localhost \
      commit -m "chore: nightly flake.lock and OMP update ($(date -I))"
  fi
fi
```

Do not move this logic into the `master` mode. Do not modify the existing `record_failure` trap: an updater failure must use its current failure record and must reach neither the closure build nor the cache-branch push.

- [ ] **Step 4: Run the focused regression test and existing Vasher checks**

Run:

```bash
bash scripts/tests/test-vasher-omp-candidate.sh
bash scripts/tests/test-vasher-bambu-exclusion.sh
bash scripts/tests/test-vasher-resource-policy.sh
bash scripts/tests/test-vasher-cache-keys.sh
```

Expected: all commands exit `0`. The focused test proves candidate-only wiring, combined staging, and order; existing tests prove Bambu exclusion, CT resource policy, and cache-key policy remain intact.

- [ ] **Step 5: Commit the implementation and regression test**

```bash
git add modules/nixos/vasher-prebuild.nix scripts/tests/test-vasher-omp-candidate.sh
git commit -m "feat: prebuild OMP on Vasher"
```

### Task 2: Document combined nightly OMP candidates

**Files:**
- Modify: `wiki/hosts.md:53-65`

**Interfaces:**
- Consumes: the candidate behavior introduced by Task 1.
- Produces: an operator-facing account of when OMP updates, how it reaches `cache-bump`, and what remains unchanged.

- [ ] **Step 1: Update the Vasher purpose bullet**

Replace the current purpose bullet with:

```markdown
- **Purpose**: prebuild Jezrien's current `master` closure and a nightly candidate that updates both flake inputs and OMP; serve retained signed paths over `http://vasher.local.ryk.sh:5000/`
```

- [ ] **Step 2: Add the candidate-promotion behavior after the promotion bullet**

Insert:

```markdown
- **OMP updates**: only the nightly candidate runs `update-omp.sh`. A successful reduced-closure build publishes its tested `flake.lock` and `modules/ai/oh-my-pi/release.json` together on `cache-bump`; the normal promotion script advances both.
```

Do not alter the deployment, resource, recovery, Bambu-exclusion, retention, or migration instructions.

- [ ] **Step 3: Verify the documented behavior and commit**

Run:

```bash
bash scripts/tests/test-vasher-omp-candidate.sh
```

Expected: exit `0`, reconfirming the behavior described by the documentation.

Commit:

```bash
git add wiki/hosts.md
git commit -m "docs: describe Vasher OMP candidates"
```

## Final verification

Run the complete targeted Vasher and OMP checks:

```bash
bash scripts/tests/test-vasher-omp-candidate.sh
bash scripts/tests/test-vasher-bambu-exclusion.sh
bash scripts/tests/test-vasher-resource-policy.sh
bash scripts/tests/test-vasher-cache-keys.sh
bash scripts/tests/test-vasher-promote.sh
nix flake check
```

Expected: every command exits `0`. `nix flake check` includes the existing `oh-my-pi-update` check, while the focused tests cover candidate integration, unchanged Bambu policy, resource policy, cache-key policy, and promotion safety.
