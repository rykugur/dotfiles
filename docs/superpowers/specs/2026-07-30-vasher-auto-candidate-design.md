# Vasher Automatic Fresh Candidate Design

**Date:** 2026-07-30  
**Status:** Approved for implementation

## Purpose

Let `master` advance normally while Vasher continuously produces a promotable cache candidate. A promotion must still be a fast-forward to the exact candidate whose reduced Jezrien closure Vasher built.

## Policy

- A stale candidate is refreshed from the newest `origin/master`.
- Every refresh runs both `nix flake update` and `modules/ai/oh-my-pi/update-omp.sh` before building.
- The nightly job forces one refresh even when `master` has not changed.
- Only one prebuild runs at a time. Multiple `master` changes while one is running collapse into one next refresh of the newest revision.
- `cache-bump` is published only after the build succeeds and only if `origin/master` still equals the revision captured at the start of that candidate.
- A stale, running, or failed candidate never changes `master`.

## Candidate states

Vasher persists a small status record under `/var/lib/vasher` containing at least the mode, target `master` revision, candidate revision when available, state (`idle`, `building`, `success`, `failed`, or `stale`), and failure exit code when applicable.

A candidate is promotable only when:

1. its state is `success`;
2. its recorded target revision equals current `origin/master`; and
3. `origin/master` is an ancestor of `origin/cache-bump`.

A completed build whose starting `master` revision is no longer current is recorded as `stale`; it is not published. The next scheduled refresh rebuilds from the newest revision.

## Scheduling

The existing 15-minute master cadence becomes the freshness probe. It compares `origin/master` with the status/candidate state and starts a refresh only when no promotable candidate covers current `master`.

The nightly candidate timer remains the update cadence backstop, but requests a forced refresh. Both paths share the same lock and worker, preventing overlapping builds.

## Promotion command

`scripts/vasher-promote.sh` keeps its clean-checkout requirement and its fast-forward-only merge. It does not start, wait for, or SSH into a Vasher build.

If `cache-bump` cannot fast-forward current `master`, it exits without modifying local or remote state and reports that the candidate for current `master` is rebuilding or unavailable. It tells the operator to retry after Vasher completes the automatic refresh.

## Failure handling

A failed refresh retains the last known-good cache roots and leaves `cache-bump` unchanged. The next 15-minute probe retries from the newest `origin/master`; no retry loop runs inside a single job.

## Non-goals

- No remote build delegation from Jezrien.
- No automatic promotion or NixOS activation.
- No test additions or test execution unless explicitly requested by the user.
