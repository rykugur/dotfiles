# Vasher Garbage-Collection Design

**Date:** 2026-08-31  
**Status:** Approved design. Awaiting written-spec review.

## Purpose

Keep Vasher candidate builds from filling the root disk with unrooted Nix store paths after a build error.

## Evidence

The candidate build on 2026-08-31 failed while Go compiled `helmfile-1.7.4`.
The build log contains `no space left on device` errors under `/build`.

Vasher has a 98 GiB root filesystem with 3.7 GiB available.
The Nix store uses 88 GiB.
A dry-run garbage collection found 30,011 dead store paths.

The OBS overlay worked on 2026-08-27.
The current error is a storage error, not the prior OBS API error.

## Decisions

### Immediate recovery

Run `nix-collect-garbage` on Vasher to remove unrooted store paths.
Nix GC roots protect the current Vasher system and the retained successful Jezrien closure.

Then start `vasher-prebuild-candidate.service`.
Make sure that the build publishes a successful candidate to `cache-bump`.

### Prebuild cleanup

Run `nix-collect-garbage` after the prebuild lock is acquired and before `nix flake update`.
The lock prevents concurrent refresh and candidate jobs during garbage collection.

This cleanup removes paths from failed or interrupted jobs before new build work starts.
It also repairs state that remains after a process kill or host restart.

### Failure cleanup

If the prebuild fails, first write the status and copy the build log.
Then run `nix-collect-garbage` as a best-effort cleanup.

The script must preserve the original exit code.
A garbage-collection error must not replace the build error or start the error trap again.
Only the top-level shell records the error.
This rule prevents command substitutions from recording the same error twice.

### Success cleanup

Keep the existing garbage collection after a successful candidate push.
The retained GC root continues to protect the latest successful Jezrien closure.

## Alternatives

Failure-only cleanup does not repair state after a process kill or host restart.
A host-wide GC timer adds schedule and concurrency behavior outside the prebuild lock.
A larger root disk delays the same accumulation and does not remove dead paths.

## Implementation scope

1. Update `modules/nixos/vasher-prebuild.sh` with prebuild and failure cleanup.
2. Preserve the existing success cleanup.
3. Recover the live Vasher store and start the candidate service.
4. Make sure that the service completes and updates `cache-bump`.

## Out of scope

- Change the candidate or refresh schedules.
- Resize the Vasher root disk.
- Change the number of retained successful closures.
- Add a host-wide Nix GC timer.
- Change package exclusions or build concurrency.

## Acceptance criteria

- A candidate run performs garbage collection before update and build work.
- A handled build error records its original status and log before garbage collection.
- A garbage-collection error does not replace the original build exit code.
- A successful run keeps the latest Jezrien closure as a GC root.
- The recovered Vasher candidate completes and updates `cache-bump`.
