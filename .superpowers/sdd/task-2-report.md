# Task 2 Report: Vasher prebuild monitor state machine

## Status

Task 2 is complete.

The commit is `540e5295ec40c464f566a5172f89509aa9d31488`.

## Changed files

- `modules/nixos/vasher-prebuild-monitor.py` defines the state types, thresholds, evaluation function, paths, and JSON helpers.
- `scripts/tests/test-vasher-prebuild-monitor.py` contains 13 focused unit tests.

The commit contains these two files. The report file is an ignored Superpowers work file.

## TDD evidence

### RED

The workstation did not have `python3` on `PATH`. The first command stopped with exit code 127.

I resolved the existing Nix store path for Python 3.14.7. I prepended that path for each required Python command.

I then ran:

```bash
python3 -m unittest scripts/tests/test-vasher-prebuild-monitor.py -v
```

The command stopped with exit code 1 before implementation. The expected error was:

```text
FileNotFoundError: [Errno 2] No such file or directory: 'modules/nixos/vasher-prebuild-monitor.py'
```

### GREEN

The first implementation run exposed an import-harness error. `dataclass` could not resolve the dynamic module because it was absent from `sys.modules`.

The test harness now registers the module before `exec_module`. This is the required importlib loading sequence for annotated dataclasses.

I ran the focused command again after implementation:

```bash
python3 -m unittest scripts/tests/test-vasher-prebuild-monitor.py -v
```

The command exited with code 0. The result was:

```text
Ran 13 tests in 0.022s

OK
```

The 13 tests cover these contracts:

- The memory threshold persists for 120 seconds.
- A safe sample clears the memory timer.
- The disk threshold persists for 60 seconds.
- Log activity resets the stall timer.
- Ten CPU seconds reset the stall timer.
- An idle build stops after 30 minutes.
- A second unsafe condition returns `stop-final` after one retry.
- A threshold timer survives a durable reload.
- Durable reload preserves the retry count, terminal-event marker, boot ID, and Nix safe timer.
- A revision change resets all monitor state.
- State and retry JSON files use mode `0600`.
- Ledger JSON uses mode `0644`.
- The ledger retains the 100 newest events in newest-first order.

I also ran:

```bash
python3 -m py_compile modules/nixos/vasher-prebuild-monitor.py
```

The command exited with code 0 and produced no output.

## Commit evidence

I ran:

```bash
git add modules/nixos/vasher-prebuild-monitor.py scripts/tests/test-vasher-prebuild-monitor.py
git commit -m "feat(vasher): add prebuild safety state machine"
```

Git created commit `540e5295ec40c464f566a5172f89509aa9d31488`.

## Self-review

- `Sample`, `Decision`, and `MonitorState` match the brief.
- The memory, swap, disk, stall, and CPU values match the brief.
- `evaluate` depends only on the supplied state, sample, and monotonic timestamp.
- The threshold order is memory, disk, then stall.
- Safe memory and disk samples clear their timers.
- Log changes and sufficient CPU activity reset stall tracking.
- A nonzero retry count changes `stop` to `stop-final`.
- The durable state includes `retry_count`, `last_terminal_at`, `boot_id`, and `nix_safe_since`.
- Revision mismatch discards stale state and creates the default state.
- `atomic_json` writes a sibling temporary file, sets its mode, and replaces the destination.
- `append_event` writes mode `0644` and keeps exactly 100 newest entries.
- The implementation adds no live sampling, subprocess action, or model call.
- No design or plan document changed.

## Concerns

The workstation does not expose `python3` on its default `PATH`. Verification required a temporary `PATH` prefix for the existing Nix store interpreter.

The Nix safe timer is durable state only. Task 2 intentionally adds no update or action behavior for this later-task field.
