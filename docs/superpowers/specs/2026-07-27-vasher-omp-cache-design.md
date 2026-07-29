# Vasher OMP Candidate Cache Design

**Date:** 2026-07-27  
**Status:** Approved design; awaiting written-spec review

## Purpose

Vasher will update Oh My Pi (OMP) alongside its nightly `nix flake update` candidate, build the resulting reduced Jezrien closure, and serve its signed output over Harmonia. A promoted `cache-bump` revision therefore contains the tested OMP release lock and the corresponding flake-lock updates in one commit.

## Existing boundaries

- OMP is packaged by `modules/ai/oh-my-pi/default.nix` from the versioned asset metadata in `modules/ai/oh-my-pi/release.json`.
- `modules/ai/oh-my-pi/update-omp.sh` queries the latest stable GitHub release, validates all four platform asset digests, atomically replaces `release.json`, and builds `.#oh-my-pi`.
- Jezrien installs OMP through its Home Manager configuration, so the `nixosConfigurations.jezrien-prebuild` closure contains the Linux OMP output.
- Vasher's candidate job already resets an isolated worktree to `origin/master`, updates `flake.lock`, builds the reduced Jezrien closure, retains its output, and conditionally force-pushes `cache-bump`.

## Design

### Candidate workflow

Only `vasher-prebuild-candidate` updates OMP. After resetting its worktree to `origin/master` and running `nix flake update`, it runs the existing OMP updater in that worktree. It then builds:

```text
nixosConfigurations.jezrien-prebuild.config.system.build.toplevel
```

That closure is the authoritative OMP build: it includes Jezrien's OMP package and is the exact closure Vasher signs, retains, and serves. The updater's standalone `.#oh-my-pi` build remains a release-metadata/package validation step; the closure build establishes deployability for Jezrien.

On success, the candidate stages both changed update inputs:

```text
flake.lock
modules/ai/oh-my-pi/release.json
```

It commits them together only when either file changed, then publishes the worktree `HEAD` to `origin/cache-bump` using `--force-with-lease`.

### Promotion

Promotion remains `scripts/vasher-promote.sh` from a clean local `master` checkout. It fast-forwards only to `origin/cache-bump`, pushes `master`, and switches the local host. No separate OMP promotion command, branch, timer, cache root, or trust configuration is introduced.

### Branch semantics

`cache-bump` is an ephemeral latest-candidate ref. Each nightly candidate is based on current `origin/master`; it can diverge from the previous candidate and thus requires `--force-with-lease` to replace that old proposal safely. The lease prevents a blind overwrite if the remote ref changes concurrently. `master` is never force-pushed.

## Failure behavior

Any failed step—GitHub release request, stable-release validation, digest validation, standalone OMP build, or reduced Jezrien closure build—causes the candidate job to fail and records failure status. It must not create or advance `cache-bump`; the next nightly run starts from clean `origin/master` and retries.

A successful candidate must retain the complete reduced closure before publishing `cache-bump`. Existing Bambu Studio exclusion behavior is unchanged: Bambu Studio remains absent from Vasher's prebuild closure and is built locally during promotion when necessary.

## Non-goals

- Updating OMP from the 15-minute `master` cache job.
- Separate OMP branches, timers, signing keys, cache roots, or promotion commands.
- Remote builder configuration or SSH build delegation from Jezrien.
- Auto-promoting OMP or any candidate to `master`.

## Verification contract

Implementation must add focused coverage proving:

1. The candidate runs the OMP updater after `nix flake update` and before the reduced closure build.
2. The candidate commit includes both `flake.lock` and `modules/ai/oh-my-pi/release.json` when changed.
3. An OMP-update failure leaves `cache-bump` unchanged and records a failed candidate.
4. A successful OMP update is represented in `cache-bump` and is available through the existing signed cache closure.
5. Existing master prebuild, Bambu exclusion, candidate serialization, and promotion-script tests continue to pass.
