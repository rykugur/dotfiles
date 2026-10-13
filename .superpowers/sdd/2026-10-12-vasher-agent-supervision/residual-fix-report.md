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

## Concerns

- None. No activation commands were run.
