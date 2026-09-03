# Task 1 Report: Candidate Identity and Exact Retry

## Changed files

- `modules/nixos/vasher-prebuild.sh`
- `scripts/tests/test-vasher-prebuild-gc.sh`
- `scripts/tests/test-vasher-prebuild-retry.sh`

## Behavior

The candidate path now creates its commit and reads its revision before `nix build` starts. The `building` and failure status records contain both revisions.

The new `retry <base-revision> <candidate-revision>` path uses the existing candidate worktree. It validates both 40-character lowercase hexadecimal revisions before it uses them.

The retry path also checks the candidate worktree HEAD and the base ancestry. It does not update the flake or OMP.

The refresh and candidate modes still use separate worktrees. The common build path keeps the existing GC-root, stale-check, branch-publication, and success behavior.

## TDD evidence

### Expected failures before the implementation

Command:

```sh
bash scripts/tests/test-vasher-prebuild-gc.sh
```

Result:

```text
exit 1
(no output; the new candidate revision assertion failed)
```

Command:

```sh
bash scripts/tests/test-vasher-prebuild-retry.sh
```

Output:

```text
vasher-prebuild: unknown mode retry
expected build exit 42, got: 2
exit 1
```

### Focused checks after the implementation

Command:

```sh
bash scripts/tests/test-vasher-prebuild-gc.sh
```

Result:

```text
PASS (exit 0, no output)
```

Command:

```sh
bash scripts/tests/test-vasher-prebuild-retry.sh
```

Result:

```text
PASS (exit 0, no output)
```

The retry test requires this exact event log:

```text
gc
build
gc
```

A flake update or OMP update adds an event and makes this test fail.

Command:

```sh
bash -n modules/nixos/vasher-prebuild.sh
```

Result:

```text
PASS (exit 0, no output)
```

## Self-review

- The implementation moves the existing update and commit logic into one function. It does not duplicate that logic.
- The candidate revision is available when the script writes the `building` status.
- The retry path validates both input revisions before Git uses them.
- The retry path requires the candidate worktree HEAD to equal the requested candidate revision.
- The retry path requires the base revision to be an ancestor of the candidate revision.
- The retry regression proves that the script does not run the flake updater or OMP updater.
- The common post-build path keeps the existing GC-root, stale-check, publication, and cleanup sequence.
- The pre-existing untracked `modules/nixos/vasher-dashboard/node_modules/` directory was not changed or committed.

## Commit

Task implementation: `95bfffb142aebc71b1d11aab51cb75681797cc1b` (`feat(vasher): preserve candidate identity for retries`)

This report is in a separate documentation commit.

## Concerns

No implementation concerns.
