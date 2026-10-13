# Residual fix report

Status: COMPLETE

Commit: `fix(vasher): prevent narrow builds from entering candidate retry`

## Changes

- A stopped narrow build transitions directly from stopping to durable `needs-attention` with reason `narrow-retry-unsupported`, before cleanup begins.
- Restart/resume from persisted `stopping`, `cleaning`, or `retrying` state applies the same mode guard.
- `_start_retry` retains a defensive narrow-mode guard, so no remaining call path can create the retry request or start `vasher-prebuild-retry.service` for a narrow sample.
- Candidate and retry-mode recovery behavior is unchanged.

## TDD evidence

- `nix shell nixpkgs#python3 -c python3 -m unittest scripts.tests.test-vasher-prebuild-monitor.RecoveryControllerTests.test_narrow_recovery_stops_and_fails_safe_without_candidate_retry scripts.tests.test-vasher-prebuild-monitor.RecoveryControllerTests.test_narrow_recovery_phases_resume_to_needs_attention` — RED: 4 expected failures. Direct recovery started cleanup and retry; persisted `stopping` started cleanup and retry; persisted `cleaning` remained cleaning; persisted `retrying` started retry.
- The same focused command after implementation — 2 tests, OK.

## Verification

- `nix shell nixpkgs#python3 -c python3 scripts/tests/test-vasher-prebuild-monitor.py` — 65 tests, OK.
- `bash scripts/tests/test-vasher-monitor-closure.sh` — exit 0; rebuilt the monitor and service closures.
- `nix flake check` — exit 0; `all checks passed!`; existing evaluation/deprecation warnings only.
- `git diff --check` — exit 0.

## Ordering follow-up

- `needs-attention` is now a silent terminal state for the current revision: terminal status updates cannot overwrite it or append events. Revision alignment still resets state when a new revision arrives.
- The live narrow-stop test now feeds the realistic post-stop `failed`/143 sample twice and verifies durable state plus a byte-identical event ledger.
- A direct `_start_retry` regression test uses the matching candidate worktree and independently proves the defensive narrow guard.

### TDD evidence

- `nix shell nixpkgs#python3 -c python3 -m unittest scripts.tests.test-vasher-prebuild-monitor.RecoveryControllerTests.test_narrow_recovery_stops_and_fails_safe_without_candidate_retry scripts.tests.test-vasher-prebuild-monitor.RecoveryControllerTests.test_start_retry_rejects_matching_narrow_worktree` — RED: the live sequence changed `needs-attention` to `complete` on the first failed/143 sample; the direct choke-point test passed.
- The same focused command after implementation — 2 tests, OK.

### Verification

- `nix shell nixpkgs#python3 -c python3 scripts/tests/test-vasher-prebuild-monitor.py` — 66 tests, OK.
- `bash scripts/tests/test-vasher-monitor-closure.sh` — exit 0; rebuilt the changed monitor and service closures.
- `nix flake check` — exit 0; `all checks passed!`; existing evaluation/deprecation warnings only.

## Concerns

- None. No activation commands were run.
