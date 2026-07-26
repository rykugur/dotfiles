# Vasher Cache-Bump Promotion Script

## Status

Approved design; awaiting specification review.

## Purpose

Provide one repeatable post-merge operator command that promotes Vasher's `cache-bump` branch into a clean local `master`, publishes it, and rebuilds the currently running NixOS host.

## Script

Create executable `scripts/vasher-promote.sh`.

The script resolves the repository root from its own location, rather than the caller's current directory. It uses `set -Eeuo pipefail` and reports each phase before executing it.

## Preconditions

The script aborts before mutation unless all conditions hold:

- The resolved repository is on branch `master`.
- The worktree has no tracked or untracked changes.
- `origin/cache-bump` exists after fetching.
- `origin/cache-bump` can fast-forward local `master`; the script never merges divergent histories or resets refs.

## Promotion flow

1. Fetch `origin`.
2. Fast-forward local `master` to `origin/cache-bump`.
3. Push the resulting `master` to `origin`.
4. Read the running host name with `hostname`.
5. Run `sudo nh os switch .#<running-hostname>` from the repository root.

The script does not accept a host argument and does not hard-code a host name. A non-NixOS host or an unmatched flake configuration naturally fails at the final `nh` invocation without changing the Git promotion behavior.

## Failure behavior

Commands fail closed. A failed fetch, precondition, fast-forward, push, or rebuild exits nonzero and prevents subsequent phases. The script does not retry, stash, force-push, reset, or roll back an already-pushed `master`.

## Verification

A disposable Git fixture proves the script rejects a dirty checkout, rejects a non-`master` branch, rejects non-fast-forward promotion, and performs the valid fetch/fast-forward/push sequence. The `nh` executable is replaced by a controlled stub in that fixture to assert it receives `os switch .#$(hostname)` without rebuilding a host during tests.
