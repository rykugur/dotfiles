# Vasher Prebuild Monitor Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add deterministic resource protection, one exact candidate retry, remote Haiku summaries, and a monitor timeline to the Vasher ledger.

**Architecture:** A Python monitor samples local systemd, Nix daemon, memory, disk, and log state. Fixed rules stop unsafe work and start allowlisted cleanup and retry units. A direct Anthropic client writes untrusted summaries to the ledger and never supplies actions.

**Tech Stack:** NixOS modules, systemd, Python 3 standard library, Bash, jq, React 19, TypeScript 5.9, Vite 7, Anthropic Messages API.

## Global Constraints

- Sample active prebuilds every 30 seconds.
- Stop after `MemAvailable < 768 MiB` or `SwapFree < 256 MiB` lasts 120 seconds.
- Stop after root free space stays less than 5 GiB for 60 seconds.
- Stop after no log growth and less than 10 CPU-seconds of combined activity lasts 30 minutes.
- Retry the exact candidate revision no more than once.
- Start a retry only with 2 GiB available memory, 1 GiB free swap, 10 GiB free disk, and Nix daemon memory below 2 GiB for 60 seconds.
- Use `claude-haiku-4-5` with a 512-token output limit and a 30-second request timeout.
- Keep the newest 100 monitor events.
- Treat model output as escaped ledger text only.
- Never parse model output into commands, paths, unit names, URLs, thresholds, or state transitions.
- The monitor runtime must not contain OpenSSH, an SSH library, or an SSH agent client.
- The monitor must not connect to a private network address.
- Preserve existing prebuild success, failure, GC-root, and promotion behavior.

---

### Task 1: Publish Candidate Identity Before Each Build

**Files:**
- Modify: `modules/nixos/vasher-prebuild.sh:4-184`
- Modify: `scripts/tests/test-vasher-prebuild-gc.sh:8-70`
- Create: `scripts/tests/test-vasher-prebuild-retry.sh`

**Interfaces:**
- Consumes: Existing prebuild environment variables and `/var/lib/vasher/worktrees/candidate`.
- Produces: `vasher-prebuild retry <base-revision> <candidate-revision>` and early `status.json.revision` publication.

- [ ] **Step 1: Extend the failure regression with candidate identity assertions**

Update the fake `git` command in `scripts/tests/test-vasher-prebuild-gc.sh` so that it handles both revision lookups:

```bash
cat > "$tmp/bin/git" <<'EOF'
#!/usr/bin/env bash
case "$*" in
  *"rev-parse origin/master"*) printf '1111111111111111111111111111111111111111\n' ;;
  *"rev-parse HEAD"*) printf '2222222222222222222222222222222222222222\n' ;;
  *"diff --cached --quiet"*) exit 1 ;;
esac
EOF
```

After the existing status assertion, add:

```bash
jq -e '
  .state == "failed" and
  .baseRevision == "1111111111111111111111111111111111111111" and
  .revision == "2222222222222222222222222222222222222222" and
  .exitCode == 42
' "$state_root/dashboard/status.json" >/dev/null
```

- [ ] **Step 2: Add a failing exact-retry regression**

Create `scripts/tests/test-vasher-prebuild-retry.sh`. Use the same temporary layout and fake token from the GC test. Record `flake update`, OMP update, GC, and build operations in `$EVENTS`.

The fake commands must return these revisions:

```bash
base=1111111111111111111111111111111111111111
candidate=2222222222222222222222222222222222222222
```

Run this command:

```bash
bash "$tmp/prebuild.sh" retry "$base" "$candidate"
```

Assert these observable results:

```bash
[[ $exit_code -eq 42 ]]
[[ $(<"$events") == $'gc\nbuild\ngc' ]]
jq -e --arg base "$base" --arg candidate "$candidate" '
  .state == "failed" and
  .mode == "retry" and
  .baseRevision == $base and
  .revision == $candidate and
  .exitCode == 42
' "$state_root/dashboard/status.json" >/dev/null
```

The test must fail because the current script rejects `retry` mode.

- [ ] **Step 3: Run both regressions and record the expected failure**

Run:

```bash
bash scripts/tests/test-vasher-prebuild-gc.sh
bash scripts/tests/test-vasher-prebuild-retry.sh
```

Expected result: the GC regression fails because the candidate revision is empty. The retry regression fails with `vasher-prebuild: unknown mode retry`.

- [ ] **Step 4: Add candidate preparation and retry preparation paths**

Refactor `modules/nixos/vasher-prebuild.sh` around these functions. Keep the existing status and trap functions unchanged.

```bash
mode=${1-}
expected_base=${2-}
expected_candidate=${3-}

validate_revision() {
  [[ $1 =~ ^[0-9a-f]{40}$ ]] || {
    printf 'vasher-prebuild: invalid revision: %s\n' "$1" >&2
    exit 2
  }
}

load_github_token() {
  [[ -s $GITHUB_TOKEN_FILE ]] || {
    printf 'vasher-prebuild: GitHub token is missing or empty\n' >&2
    exit 1
  }
  github_token=$(<"$GITHUB_TOKEN_FILE")
  nix_config="${NIX_CONFIG-}${NIX_CONFIG:+$'\n'}access-tokens = github.com=$github_token"
  unset github_token
}

prepare_updated_candidate() {
  write_status preparing null
  nix-collect-garbage
  if [[ ! -e $worktree/.git ]]; then
    mkdir -p "$(dirname "$worktree")"
    git -C "$repo" worktree add --detach "$worktree" "$base_revision"
  fi
  git -C "$worktree" reset --hard "$base_revision"
  NIX_CONFIG="$nix_config" nix flake update --flake "$worktree"
  (
    cd "$worktree"
    NIX_CONFIG="$nix_config" bash "$OMP_UPDATER"
  )
  git -C "$worktree" add flake.lock modules/ai/oh-my-pi/release.json
  if ! git -C "$worktree" diff --cached --quiet; then
    git -C "$worktree" -c user.name=vasher -c user.email=vasher@localhost \
      commit -m "chore: refreshed flake.lock and OMP update ($(date -I))"
  fi
  candidate_revision=$(git -C "$worktree" rev-parse HEAD)
}

prepare_exact_retry() {
  validate_revision "$expected_base"
  validate_revision "$expected_candidate"
  base_revision=$expected_base
  candidate_revision=$expected_candidate
  [[ -e $worktree/.git ]] || {
    printf 'vasher-prebuild: retry worktree is missing\n' >&2
    exit 1
  }
  [[ $(git -C "$worktree" rev-parse HEAD) == "$candidate_revision" ]] || {
    printf 'vasher-prebuild: retry worktree does not match %s\n' "$candidate_revision" >&2
    exit 1
  }
  git -C "$worktree" merge-base --is-ancestor "$base_revision" "$candidate_revision"
  write_status preparing null
  nix-collect-garbage
}
```

Use this mode dispatch after the prebuild lock opens:

```bash
case $mode in
  refresh) flock -n 9 || exit 0; lock_acquired=true ;;
  candidate | retry) flock 9; lock_acquired=true ;;
  *) printf 'vasher-prebuild: unknown mode %s\n' "$mode" >&2; exit 2 ;;
esac
```

Use this preparation flow before the common build path:

```bash
repo=/var/lib/vasher/repo
roots=/var/lib/vasher/gcroots
worktree=/var/lib/vasher/worktrees/"$mode"
[[ $mode == retry ]] && worktree=/var/lib/vasher/worktrees/candidate
mkdir -p "$roots"
[[ -d $repo/.git ]] || git clone "$REPO_URL" "$repo"


if [[ $mode == retry ]]; then
  load_github_token
  prepare_exact_retry
else
  git -C "$repo" fetch --prune origin
  base_revision=$(git -C "$repo" rev-parse origin/master)
  if [[ $mode == refresh ]] && candidate_covers_base; then
    write_status idle null
    exit 0
  fi
  load_github_token
  prepare_updated_candidate
fi

write_status building null
out=$(NIX_CONFIG="$nix_config" nix build "$worktree#$TARGET_ATTR" --no-link --print-out-paths)
unset nix_config
```

Remove the old post-build `git add`, commit, and candidate revision block. Keep GC-root creation, stale detection, branch publication, and success cleanup after the common build.

- [ ] **Step 5: Run the focused prebuild tests**

Run:

```bash
bash scripts/tests/test-vasher-prebuild-gc.sh
bash scripts/tests/test-vasher-prebuild-retry.sh
bash -n modules/nixos/vasher-prebuild.sh
```

Expected result: all commands exit `0`. The retry event log contains no flake update or OMP update.

- [ ] **Step 6: Commit the candidate identity change**

```bash
git add modules/nixos/vasher-prebuild.sh scripts/tests/test-vasher-prebuild-gc.sh scripts/tests/test-vasher-prebuild-retry.sh
git commit -m "feat(vasher): preserve candidate identity for retries"
```

---

### Task 2: Add the Deterministic Monitor State Machine

**Files:**
- Create: `modules/nixos/vasher-prebuild-monitor.py`
- Create: `scripts/tests/test-vasher-prebuild-monitor.py`

**Interfaces:**
- Consumes: `Sample`, the current `MonitorState`, and monotonic timestamps.
- Produces: `Decision(action, reason)`, atomic monitor state, retry request JSON, and ledger events.

- [ ] **Step 1: Write failing threshold and retry tests**

Load the monitor module from its file path with `importlib.util.spec_from_file_location`. Use `unittest` and fake samples.

Define a helper with safe defaults:

```python
def sample(at: float, **changes: object) -> monitor.Sample:
    values = {
        "at": at,
        "active_unit": "vasher-prebuild-candidate.service",
        "mode": "candidate",
        "status_state": "building",
        "status_updated_at": "2026-09-02T22:00:00Z",
        "exit_code": None,
        "base_revision": "1" * 40,
        "revision": "2" * 40,
        "mem_available": 4 * monitor.GIB,
        "swap_free": 2 * monitor.GIB,
        "memory_pressure_full": 0.0,
        "disk_free": 20 * monitor.GIB,
        "nix_memory": 256 * monitor.MIB,
        "combined_cpu_seconds": at,
        "log_size": 100,
    }
    values.update(changes)
    return monitor.Sample(**values)
```

Add tests for these contracts:

```python
def test_memory_threshold_requires_120_seconds(self):
    state = monitor.MonitorState.for_revision("1" * 40, "2" * 40)
    state, decision = monitor.evaluate(state, sample(0, mem_available=700 * monitor.MIB))
    self.assertIsNone(decision)
    state, decision = monitor.evaluate(state, sample(119, mem_available=700 * monitor.MIB))
    self.assertIsNone(decision)
    state, decision = monitor.evaluate(state, sample(120, mem_available=700 * monitor.MIB))
    self.assertEqual(decision, monitor.Decision("stop", "memory"))


def test_safe_sample_clears_memory_timer(self):
    state = monitor.MonitorState.for_revision("1" * 40, "2" * 40)
    state, _ = monitor.evaluate(state, sample(0, swap_free=200 * monitor.MIB))
    state, _ = monitor.evaluate(state, sample(90))
    state, decision = monitor.evaluate(state, sample(180, swap_free=200 * monitor.MIB))
    self.assertIsNone(decision)


def test_disk_threshold_requires_60_seconds(self):
    state = monitor.MonitorState.for_revision("1" * 40, "2" * 40)
    state, _ = monitor.evaluate(state, sample(0, disk_free=4 * monitor.GIB))
    state, decision = monitor.evaluate(state, sample(60, disk_free=4 * monitor.GIB))
    self.assertEqual(decision, monitor.Decision("stop", "disk"))


def test_log_or_cpu_activity_prevents_stall(self):
    state = monitor.MonitorState.for_revision("1" * 40, "2" * 40)
    state, _ = monitor.evaluate(state, sample(0))
    state, _ = monitor.evaluate(state, sample(900, log_size=101, combined_cpu_seconds=901))
    state, decision = monitor.evaluate(state, sample(1800, log_size=101, combined_cpu_seconds=910))
    self.assertIsNone(decision)


def test_idle_build_stops_after_30_minutes(self):
    state = monitor.MonitorState.for_revision("1" * 40, "2" * 40)
    state, _ = monitor.evaluate(state, sample(0, combined_cpu_seconds=0))
    state, decision = monitor.evaluate(state, sample(1800, combined_cpu_seconds=9))
    self.assertEqual(decision, monitor.Decision("stop", "stall"))


def test_second_unsafe_condition_never_retries(self):
    state = monitor.MonitorState.for_revision("1" * 40, "2" * 40)
    state.retry_count = 1
    state.phase = "retrying"
    state, decision = monitor.evaluate(state, sample(0, mem_available=700 * monitor.MIB))
    state, decision = monitor.evaluate(state, sample(120, mem_available=700 * monitor.MIB))
    self.assertEqual(decision, monitor.Decision("stop-final", "memory"))
```

- [ ] **Step 2: Run the state-machine tests and record the expected failure**

Run:

```bash
python3 -m unittest scripts/tests/test-vasher-prebuild-monitor.py -v
```

Expected result: FAIL because `modules/nixos/vasher-prebuild-monitor.py` does not exist.

- [ ] **Step 3: Implement the pure state types and threshold evaluation**

Create `modules/nixos/vasher-prebuild-monitor.py` with these public types and constants:

```python
#!/usr/bin/env python3
from __future__ import annotations

import json
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Literal

MIB = 1024 * 1024
GIB = 1024 * MIB
MEMORY_SECONDS = 120
DISK_SECONDS = 60
STALL_SECONDS = 30 * 60
MEMORY_LIMIT = 768 * MIB
SWAP_LIMIT = 256 * MIB
DISK_LIMIT = 5 * GIB
STALL_CPU_SECONDS = 10

Action = Literal["stop", "stop-final"]


@dataclass(frozen=True)
class Sample:
    at: float
    active_unit: str | None
    mode: str
    status_state: str
    status_updated_at: str
    exit_code: int | None
    base_revision: str
    revision: str
    mem_available: int
    swap_free: int
    disk_free: int
    memory_pressure_full: float
    nix_memory: int
    combined_cpu_seconds: float
    log_size: int


@dataclass(frozen=True)
class Decision:
    action: Action
    reason: Literal["memory", "disk", "stall"]


@dataclass
class MonitorState:
    base_revision: str
    revision: str
    phase: str = "observing"
    retry_count: int = 0
    memory_since: float | None = None
    last_terminal_at: str = ""
    boot_id: str = ""
    disk_since: float | None = None
    nix_safe_since: float | None = None
    stall_since: float | None = None
    stall_cpu_start: float = 0.0
    last_log_size: int = 0

    @classmethod
    def for_revision(cls, base_revision: str, revision: str) -> "MonitorState":
        return cls(base_revision=base_revision, revision=revision)
```

Implement `evaluate(state, sample)` with these rules:

```python
def _timer(started: float | None, active: bool, now: float) -> float | None:
    if not active:
        return None
    return now if started is None else started


def evaluate(state: MonitorState, sample: Sample) -> tuple[MonitorState, Decision | None]:
    memory_low = sample.mem_available < MEMORY_LIMIT or sample.swap_free < SWAP_LIMIT
    state.memory_since = _timer(state.memory_since, memory_low, sample.at)
    state.disk_since = _timer(state.disk_since, sample.disk_free < DISK_LIMIT, sample.at)

    if sample.log_size != state.last_log_size:
        state.last_log_size = sample.log_size
        state.stall_since = sample.at
        state.stall_cpu_start = sample.combined_cpu_seconds
    elif state.stall_since is None:
        state.stall_since = sample.at
        state.stall_cpu_start = sample.combined_cpu_seconds
    elif sample.combined_cpu_seconds - state.stall_cpu_start >= STALL_CPU_SECONDS:
        state.stall_since = sample.at
        state.stall_cpu_start = sample.combined_cpu_seconds

    reason = None
    if state.memory_since is not None and sample.at - state.memory_since >= MEMORY_SECONDS:
        reason = "memory"
    elif state.disk_since is not None and sample.at - state.disk_since >= DISK_SECONDS:
        reason = "disk"
    elif state.stall_since is not None and sample.at - state.stall_since >= STALL_SECONDS:
        reason = "stall"

    if reason is None:
        return state, None
    action: Action = "stop-final" if state.retry_count else "stop"
    return state, Decision(action, reason)
```

- [ ] **Step 4: Add durable JSON and atomic event helpers**

Add these interfaces:

```python
STATE_PATH = Path("/var/lib/vasher/monitor/state.json")
EVENTS_PATH = Path("/var/lib/vasher/dashboard/events.json")
RETRY_PATH = Path("/var/lib/vasher/monitor/retry.json")


def atomic_json(path: Path, value: object, mode: int = 0o600) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_name(f".{path.name}.tmp")
    temporary.write_text(json.dumps(value, separators=(",", ":")) + "\n")
    temporary.chmod(mode)
    temporary.replace(path)


def load_state(path: Path, base_revision: str, revision: str) -> MonitorState:
    try:
        value = json.loads(path.read_text())
        state = MonitorState(**value)
    except (FileNotFoundError, json.JSONDecodeError, TypeError):
        return MonitorState.for_revision(base_revision, revision)
    if (state.base_revision, state.revision) != (base_revision, revision):
        return MonitorState.for_revision(base_revision, revision)
    return state


def append_event(path: Path, event: dict[str, object]) -> None:
    try:
        events = json.loads(path.read_text())
    except (FileNotFoundError, json.JSONDecodeError):
        events = []
    atomic_json(path, [event, *events][:100], mode=0o644)
```

Add tests that reload `retry_count=1`, reset state for a different revision, and retain exactly 100 newest events.

- [ ] **Step 5: Run the monitor unit tests**

Run:

```bash
python3 -m unittest scripts/tests/test-vasher-prebuild-monitor.py -v
python3 -m py_compile modules/nixos/vasher-prebuild-monitor.py
```

Expected result: all tests pass.

- [ ] **Step 6: Commit the state machine**

```bash
git add modules/nixos/vasher-prebuild-monitor.py scripts/tests/test-vasher-prebuild-monitor.py
git commit -m "feat(vasher): add prebuild safety state machine"
```

---

### Task 3: Add Local Sampling and Allowlisted Recovery

**Files:**
- Modify: `modules/nixos/vasher-prebuild-monitor.py`
- Modify: `scripts/tests/test-vasher-prebuild-monitor.py`

**Interfaces:**
- Consumes: Local systemd properties, `/proc/meminfo`, filesystem statistics, status JSON, and current log metadata.
- Produces: `SystemReader.sample()`, fixed local service actions, and state transitions through cleanup and one retry.

- [ ] **Step 1: Write failing sampling and action-order tests**

Use a fake command runner that records exact argument tuples. Add tests for these contracts:

```python
def test_recovery_stops_cleans_then_retries(self):
    runner = FakeRunner(
        active={"vasher-prebuild-candidate.service": True},
        cleanup_result=0,
    )
    controller = monitor.Controller(runner, state_path, events_path, retry_path)
    controller.recover(unsafe_sample, monitor.Decision("stop", "memory"))
    self.assertEqual(
        runner.calls,
        [
            ("systemctl", "stop", "vasher-prebuild-candidate.service"),
            ("systemctl", "start", "vasher-prebuild-cleanup.service"),
            ("systemctl", "start", "--no-block", "vasher-prebuild-retry.service"),
        ],
    )


def test_failed_precondition_records_needs_attention(self):
    controller.recover(
        dataclasses.replace(unsafe_sample, disk_free=9 * monitor.GIB),
        monitor.Decision("stop", "disk"),
    )
    self.assertNotIn(("systemctl", "start", "--no-block", "vasher-prebuild-retry.service"), runner.calls)
    self.assertEqual(controller.state.phase, "needs-attention")


def test_retry_count_is_saved_before_retry_start(self):
    controller.recover(unsafe_sample, monitor.Decision("stop", "memory"))
    saved = json.loads(state_path.read_text())
    self.assertEqual(saved["retry_count"], 1)
    self.assertEqual(saved["phase"], "retrying")

```
Add one restart test with a persisted recovery phase and two boot IDs:

```python
def test_host_reboot_during_recovery_requires_attention(self):
    state = monitor.MonitorState.for_revision("1" * 40, "2" * 40)
    state.phase = "cleaning"
    state.boot_id = "old-boot"
    monitor.atomic_json(state_path, dataclasses.asdict(state))
    controller = monitor.Controller(
        runner,
        state_path,
        events_path,
        retry_path,
        boot_id="new-boot",
    )
    self.assertEqual(controller.state.phase, "needs-attention")
    self.assertNotIn(
        ("systemctl", "start", "--no-block", "vasher-prebuild-retry.service"),
        runner.calls,
    )
```

Add fake memory and pressure files, fake `systemctl show` output, fake disk values, and a fake log file. Assert all conversions exactly.

- [ ] **Step 2: Run the focused tests and record the expected failure**

Run:

```bash
python3 -m unittest scripts/tests/test-vasher-prebuild-monitor.py -v
```

Expected result: FAIL because `SystemReader` and `Controller` do not exist.

- [ ] **Step 3: Implement local sampling without shell evaluation**

Add `import os`, `import subprocess`, and `import time` with the existing imports.

Implement `Runner` with this fixed subprocess boundary:

```python
class Runner:
    def run(
        self,
        arguments: list[str],
        *,
        check: bool = True,
    ) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            arguments,
            check=check,
            text=True,
            capture_output=True,
            shell=False,
        )
```

Add `SystemReader` methods for these sources:

```python
SYSTEMCTL = "/run/current-system/sw/bin/systemctl"
STATUS_PATH = Path("/var/lib/vasher/dashboard/status.json")
LOG_PATH = Path("/var/lib/vasher/dashboard/current.log")
PRESSURE_PATH = Path("/proc/pressure/memory")
ACTIVE_UNITS = (
    "vasher-prebuild-candidate.service",
    "vasher-prebuild-retry.service",
)


def read_meminfo(path: Path = Path("/proc/meminfo")) -> dict[str, int]:
    values: dict[str, int] = {}
    for line in path.read_text().splitlines():
        name, raw = line.split(":", 1)
        values[name] = int(raw.split()[0]) * 1024
    return values


def read_memory_pressure(path: Path = PRESSURE_PATH) -> float:
    for line in path.read_text().splitlines():
        fields = line.split()
        if fields and fields[0] == "full":
            values = dict(item.split("=", 1) for item in fields[1:])
            return float(values["avg10"])
    return 0.0


def systemd_values(runner: Runner, unit: str, properties: tuple[str, ...]) -> dict[str, str]:
    result = runner.run([SYSTEMCTL, "show", unit, *[f"--property={item}" for item in properties]])
    return dict(line.split("=", 1) for line in result.stdout.splitlines() if "=" in line)
```

Store the pressure value in `Sample.memory_pressure_full`. Include this value in safety events.

`SystemReader.sample()` must select the active candidate or retry unit. It must add CPU seconds from that unit and `nix-daemon.service`.

The method must always read status data. It returns terminal `success` or `failed` samples with `active_unit=None`.

Use `os.statvfs("/")` for free disk bytes. Use `LOG_PATH.stat().st_size`, or zero when the file is absent.

Reject status data unless both revisions match `^[0-9a-f]{40}$`. Invalid data creates an error event and causes no action.

- [ ] **Step 4: Implement the fixed recovery controller**

`Controller.recover()` must use only these exact command lists:

```python
STOP_UNITS = {
    "vasher-prebuild-candidate.service",

    "vasher-prebuild-retry.service",
}

runner.run([SYSTEMCTL, "stop", sample.active_unit], check=True)
runner.run([SYSTEMCTL, "start", "vasher-prebuild-cleanup.service"], check=True)
runner.run([SYSTEMCTL, "start", "--no-block", "vasher-prebuild-retry.service"], check=True)
```

When the controller first sees `status_state="building"` for a new revision, append one `build-observed` event without inference.

Before the retry start, write this exact request structure with `atomic_json`:

```python
request = {
    "baseRevision": sample.base_revision,
    "revision": sample.revision,
}
atomic_json(RETRY_PATH, request, mode=0o644)
```

Require these retry preconditions:

```python
if sample.nix_memory < 2 * GIB:
    state.nix_safe_since = sample.at if state.nix_safe_since is None else state.nix_safe_since
else:
    state.nix_safe_since = None
nix_memory_below_limit_for = (
    0 if state.nix_safe_since is None else sample.at - state.nix_safe_since
)

return (
    sample.mem_available >= 2 * GIB
    and sample.swap_free >= GIB
    and sample.disk_free >= 10 * GIB
    and sample.nix_memory < 2 * GIB
    and nix_memory_below_limit_for >= 60
    and state.retry_count == 0
)
```

After a cleanup, take new samples until the Nix memory rule passes or 10 minutes elapse. A timeout records `needs-attention`.

For `stop-final`, stop the active retry unit, set `phase="needs-attention"`, write the state, and do not run cleanup or another retry.

Read `/proc/sys/kernel/random/boot_id` during controller initialization. If the boot ID changed during `stopping`, `cleaning`, or `retrying`, record `needs-attention`.

If only the monitor process restarted, the boot ID stays equal. Resume the transition that matches the actual local unit state.

- [ ] **Step 5: Implement the 30-second service loop**

Add `main()` with signal-safe termination:

```python
def main() -> int:
    runner = Runner()
    reader = SystemReader(runner)
    controller = Controller(runner, STATE_PATH, EVENTS_PATH, RETRY_PATH)
    while True:
        try:
            sample = reader.sample()
            if sample is not None:
                controller.observe(sample)
        except InvalidStatus as error:
            controller.record_error(str(error))
        except Exception as error:
            controller.record_error(f"monitor error: {type(error).__name__}: {error}")
        time.sleep(30)
```

`Controller.observe()` must append one terminal event when `status_state` is `success` or `failed`. It deduplicates that event with `status_updated_at`.

The controller saves `status_updated_at` in `MonitorState.last_terminal_at` before it requests a model summary. It does not evaluate thresholds without an active unit.

Do not use `eval`, `exec`, `shell=True`, URLs from input, or command strings.

- [ ] **Step 6: Run recovery and syntax tests**

Run:

```bash
python3 -m unittest scripts/tests/test-vasher-prebuild-monitor.py -v
python3 -m py_compile modules/nixos/vasher-prebuild-monitor.py
```

Expected result: all tests pass. The fake runner shows stop, cleanup, and retry in that order.

- [ ] **Step 7: Commit local monitoring and recovery**

```bash
git add modules/nixos/vasher-prebuild-monitor.py scripts/tests/test-vasher-prebuild-monitor.py
git commit -m "feat(vasher): monitor and recover unsafe prebuilds"
```

---

### Task 4: Add Bounded Haiku Incident Summaries

**Files:**
- Modify: `modules/nixos/vasher-prebuild-monitor.py`
- Modify: `scripts/tests/test-vasher-prebuild-monitor.py`

**Interfaces:**
- Consumes: A fixed Anthropic key file and a bounded local evidence bundle.
- Produces: Plain summary text stored in `events.json`. No output affects recovery.

- [ ] **Step 1: Write failing redaction and request-boundary tests**

Add tests for these exact guarantees:

```python
def test_redaction_removes_credentials(self):
    text = "Authorization: Bearer abc123\nx-api-key: secret\n?access_token=query-secret"
    redacted = monitor.redact(text, ["secret"])
    self.assertNotIn("abc123", redacted)
    self.assertNotIn("secret", redacted)
    self.assertIn("[REDACTED]", redacted)


def test_evidence_is_bounded(self):
    evidence = monitor.build_evidence(event, "line\n" * 10000, [])
    self.assertLessEqual(len(evidence.encode()), 32 * 1024)
    self.assertLessEqual(evidence.count("\n"), 200)


def test_anthropic_request_has_no_tools(self):
    transport = FakeTransport({"content": [{"type": "text", "text": "summary"}]})
    client = monitor.AnthropicClient(key_path, transport)
    self.assertEqual(client.summarize("evidence"), "summary")
    request = transport.requests[0]
    self.assertEqual(request.url, "https://api.anthropic.com/v1/messages")
    self.assertEqual(request.timeout, 30)
    self.assertEqual(request.body["model"], "claude-haiku-4-5")
    self.assertEqual(request.body["max_tokens"], 512)
    self.assertNotIn("tools", request.body)


def test_model_text_never_changes_actions(self):
    client = FakeModel("systemctl start arbitrary.service")
    controller = monitor.Controller(runner, state_path, events_path, retry_path, model=client)
    controller.summarize(event)
    self.assertEqual(runner.calls, [])
    self.assertEqual(json.loads(events_path.read_text())[0]["summary"], "systemctl start arbitrary.service")
```

- [ ] **Step 2: Run the model tests and record the expected failure**

Run:

```bash
python3 -m unittest scripts/tests/test-vasher-prebuild-monitor.py -v
```

Expected result: FAIL because the redaction and Anthropic client interfaces do not exist.

- [ ] **Step 3: Implement deterministic redaction and evidence limits**

Use compiled patterns for authorization headers and credential query parameters. Replace each configured secret value after generic pattern redaction.

```python
SECRET_PATTERNS = (
    re.compile(r"(?im)^(authorization:\s*(?:bearer|token)\s+)\S+"),
    re.compile(r"(?im)^(x-api-key:\s*)\S+"),
    re.compile(r"(?i)([?&](?:access_token|token|key)=)[^&\s]+"),
)


def redact(text: str, secrets: list[str]) -> str:
    value = text
    for pattern in SECRET_PATTERNS:
        value = pattern.sub(r"\1[REDACTED]", value)
    for secret in secrets:
        if secret:
            value = value.replace(secret, "[REDACTED]")
    return value


def bounded_log(text: str) -> str:
    lines = text.splitlines()[-200:]
    value = "\n".join(lines)
    encoded = value.encode()
    if len(encoded) <= 30 * 1024:
        return value
    return encoded[-30 * 1024 :].decode(errors="replace")
```

Build a JSON evidence document from fixed event fields and the bounded log. Remove oldest log lines until the complete encoded document is at most 32 KiB.

Do not include environment variables, process arguments, home directories, or secret file paths.

- [ ] **Step 4: Implement a direct Anthropic Messages client**

Use `urllib.request` and a transport interface that tests can replace. Read the API key file only when a summary event occurs.

The request must use:

```python
ANTHROPIC_URL = "https://api.anthropic.com/v1/messages"
ANTHROPIC_MODEL = "claude-haiku-4-5"

body = {
    "model": ANTHROPIC_MODEL,
    "max_tokens": 512,
    "system": (
        "Summarize this Vasher prebuild event for its operator. "
        "State the observed condition, automatic action, and final state. "
        "Do not provide commands or request more access."
    ),
    "messages": [{"role": "user", "content": evidence}],
}

headers = {
    "content-type": "application/json",
    "anthropic-version": "2023-06-01",
    "x-api-key": key,
}
```

Use a 30-second timeout. Accept only the first response content item with `type == "text"`. Limit the stored summary to 4096 Unicode characters.

Catch HTTP, URL, timeout, JSON, and response-shape errors. Record `inference-error` without headers, bodies, or the API key.

- [ ] **Step 5: Trigger summaries only for terminal events**

Call the model after these event types:

```python
SUMMARY_EVENTS = {
    "safety-stop",
    "build-failed",
    "build-succeeded",
    "needs-attention",
}
```

The monitor must keep recovery synchronous and independent. Store the base event first, request the summary, then update only that event by its generated event ID.

For a safety event, complete the fixed recovery transition before the model request. The 30-second API timeout cannot delay stop, cleanup, or retry actions.

Do not request another summary for an event that already has `summary` or `inferenceError`.

- [ ] **Step 6: Run the full monitor test file**

Run:

```bash
python3 -m unittest scripts/tests/test-vasher-prebuild-monitor.py -v
python3 -m py_compile modules/nixos/vasher-prebuild-monitor.py
```

Expected result: all tests pass. The fake transport receives no `tools` field, and malicious model text causes no command.

- [ ] **Step 7: Commit the model boundary**

```bash
git add modules/nixos/vasher-prebuild-monitor.py scripts/tests/test-vasher-prebuild-monitor.py
git commit -m "feat(vasher): summarize prebuild incidents with Haiku"
```

---

### Task 5: Wire Secure NixOS Services and Ledger Storage

**Files:**
- Modify: `modules/nixos/vasher-prebuild.nix:5-156`
- Create: `scripts/tests/test-vasher-monitor-closure.sh`

**Interfaces:**
- Consumes: `vasher-prebuild-monitor.py`, the prebuild executable, and `swoleflake/anthropic_api_key`.
- Produces: monitor, cleanup, and retry services plus `/api/events.json`.

- [ ] **Step 1: Write the closure and configuration regression**

Create `scripts/tests/test-vasher-monitor-closure.sh`. Evaluate the monitor executable and fail when its closure contains OpenSSH:

```bash
#!/usr/bin/env bash
set -euo pipefail

root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)
cd "$root"

exec_start=$(nix eval --raw '.#nixosConfigurations.vasher.config.systemd.services.vasher-prebuild-monitor.serviceConfig.ExecStart')
monitor_path=${exec_start%%/bin/*}
while IFS= read -r path; do
  case ${path##*/} in
    *openssh*)
      printf 'monitor closure contains OpenSSH: %s\n' "$path" >&2
      exit 1
      ;;
  esac
done < <(nix-store -qR "$monitor_path")
```

Extend the same script with exact Nix assertions:

```bash
monitor_env=$(nix eval --json '.#nixosConfigurations.vasher.config.systemd.services.vasher-prebuild-monitor.environment')
jq -e 'has("GIT_SSH_COMMAND") | not' <<< "$monitor_env" >/dev/null

denied=$(nix eval --json '.#nixosConfigurations.vasher.config.systemd.services.vasher-prebuild-monitor.serviceConfig.IPAddressDeny')
jq -e 'contains([
  "10.0.0.0/8",
  "172.16.0.0/12",
  "192.168.0.0/16",
  "fc00::/7"
])' <<< "$denied" >/dev/null

retry_exec=$(nix eval --raw '.#nixosConfigurations.vasher.config.systemd.services.vasher-prebuild-retry.serviceConfig.ExecStart')
case $retry_exec in
  */bin/vasher-prebuild-retry) ;;
  *)
    printf 'unexpected retry command: %s\n' "$retry_exec" >&2
    exit 1
    ;;
esac
```

- [ ] **Step 2: Run the closure test and record the expected failure**

Run:

```bash
bash scripts/tests/test-vasher-monitor-closure.sh
```

Expected result: FAIL because `vasher-prebuild-monitor.service` does not exist.

- [ ] **Step 3: Package the monitor and fixed retry wrapper**

In `modules/nixos/vasher-prebuild.nix`, add:

```nix
monitor = pkgs.writers.writePython3Bin "vasher-prebuild-monitor" {
  flakeIgnore = [ "E501" ];
} (builtins.readFile ./vasher-prebuild-monitor.py);

retry = pkgs.writeShellApplication {
  name = "vasher-prebuild-retry";
  runtimeInputs = [ pkgs.jq ];
  text = ''
    request=/var/lib/vasher/monitor/retry.json
    base=$(jq -er '.baseRevision | select(test("^[0-9a-f]{40}$"))' "$request")
    revision=$(jq -er '.revision | select(test("^[0-9a-f]{40}$"))' "$request")
    exec ${prebuild}/bin/vasher-prebuild retry "$base" "$revision"
  '';
};
```

The monitor package references Python only. Do not add Git, Nix, curl, OpenSSH, or a shell command runner to its package.

- [ ] **Step 4: Add the SOPS secret and local worker units**

Add the API key secret:

```nix
sops.secrets."swoleflake/anthropic_api_key" = {
  key = "swoleflake/anthropic_api_key";
  owner = "root";
  group = "root";
  mode = "0400";
};
```

Insert these fixed units in the existing `systemd.services` attribute set:

```nix
vasher-prebuild-cleanup = service "cleanup" // {
  description = "Collect garbage before a Vasher prebuild retry";
  serviceConfig = serviceConfig // {
    ExecStart = "${pkgs.nix}/bin/nix-collect-garbage";
  };
};

vasher-prebuild-retry = service "retry" // {
  description = "Retry the recorded Vasher candidate";
  serviceConfig = serviceConfig // {
    ExecStart = "${retry}/bin/vasher-prebuild-retry";
  };
};
```

Do not give either unit a timer or `wantedBy` value.

- [ ] **Step 5: Add the hardened monitor unit**

Insert this service in the same attribute set. Keep its environment separate from the prebuild SSH environment:

```nix
vasher-prebuild-monitor = {
  description = "Monitor Vasher prebuild resource safety";
  wantedBy = [ "multi-user.target" ];
  after = [ "network-online.target" ];
  wants = [ "network-online.target" ];
  environment = {
    ANTHROPIC_API_KEY_FILE = config.sops.secrets."swoleflake/anthropic_api_key".path;
  };
  serviceConfig = {
    Type = "simple";
    ExecStart = "${monitor}/bin/vasher-prebuild-monitor";
    Restart = "always";
    RestartSec = "10s";
    User = "root";
    Group = "root";
    UMask = "0077";
    NoNewPrivileges = true;
    PrivateDevices = true;
    PrivateTmp = true;
    ProtectHome = true;
    ProtectSystem = "strict";
    ProtectControlGroups = true;
    ProtectKernelModules = true;
    ProtectKernelTunables = true;
    RestrictSUIDSGID = true;
    LockPersonality = true;
    MemoryDenyWriteExecute = true;
    RestrictRealtime = true;
    CapabilityBoundingSet = "";
    ReadWritePaths = [
      "/var/lib/vasher/dashboard"
      "/var/lib/vasher/monitor"
    ];
    ReadOnlyPaths = [
      config.sops.secrets."swoleflake/anthropic_api_key".path
    ];
    InaccessiblePaths = [
      "/home"
      "/root/.ssh"
      config.sops.secrets."swoleflake/deploy_key".path
      config.sops.secrets."swoleflake/github_token".path
      "/run/current-system/sw/bin/ssh"
      "/run/current-system/sw/bin/scp"
      "/run/current-system/sw/bin/sftp"
      "/run/current-system/sw/bin/ssh-add"
      "/run/current-system/sw/bin/ssh-agent"
    ];
    IPAddressDeny = [
      "10.0.0.0/8"
      "172.16.0.0/12"
      "192.168.0.0/16"
      "169.254.0.0/16"
      "fc00::/7"
      "fe80::/10"
    ];
  };
};
```


- [ ] **Step 6: Initialize and expose the event ledger**

Add tmpfiles entries:

```nix
systemd.tmpfiles.rules = [
  "d /var/lib/vasher/dashboard 0755 vasher vasher -"
  "d /var/lib/vasher/monitor 0755 root root -"
  "f /var/lib/vasher/dashboard/events.json 0644 root root - []"
];
```

Add this Caddy handler before the frontend fallback:

```caddyfile
handle /api/events.json {
  rewrite * /events.json
  root * /var/lib/vasher/dashboard
  file_server
}
```

- [ ] **Step 7: Add the encrypted key without reading it**

Ask the operator to add `swoleflake/anthropic_api_key` to the existing encrypted Vasher SOPS document. Do not print, inspect, or pass the key through command arguments.

Make sure that the encrypted file remains the only file with secret content.

- [ ] **Step 8: Run Nix and closure checks**

Run:

```bash
bash scripts/tests/test-vasher-monitor-closure.sh
nix build --no-link .#nixosConfigurations.vasher.config.system.build.toplevel
```

Expected result: both commands exit `0`. The closure test reports no OpenSSH path for the monitor executable.

- [ ] **Step 9: Commit service integration**

```bash
git add modules/nixos/vasher-prebuild.nix scripts/tests/test-vasher-monitor-closure.sh
git commit -m "feat(vasher): run hardened prebuild monitor"
```

Commit the encrypted SOPS file separately:

```bash
git add modules/hosts/vasher/secrets.yaml
git commit -m "chore(vasher): add monitor inference key"
```

---

### Task 6: Show Monitor Events in the Vasher Ledger

**Files:**
- Modify: `modules/nixos/vasher-dashboard/src/main.tsx:6-126`
- Create: `modules/nixos/vasher-dashboard/src/event-text.ts`
- Modify: `modules/nixos/vasher-dashboard/src/dashboard.css:1-30`
- Modify: `modules/nixos/vasher-dashboard/package.json:6-9`
- Create: `modules/nixos/vasher-dashboard/test/event-timeline.test.ts`

**Interfaces:**
- Consumes: `/api/events.json` as `MonitorEvent[]`.
- Produces: A newest-first event timeline with escaped model summaries and explicit action metadata.

- [ ] **Step 1: Write a failing event rendering test**

Create a pure `renderEventText(event)` helper outside the TSX entry point. Create `test/event-timeline.test.ts`:

```typescript
import assert from "node:assert/strict";
import test from "node:test";
import { renderEventText } from "../src/event-text.ts";

test("event text preserves model content as text", () => {
  const value = renderEventText({
    id: "event-1",
    timestamp: "2026-09-02T22:00:00Z",
    revision: "2".repeat(40),
    type: "needs-attention",
    severity: "error",
    reason: "memory",
    metrics: {},
    action: "stop-final",
    summary: "<script>globalThis.pwned = true</script>",
  });
  assert.equal(value.summary, "<script>globalThis.pwned = true</script>");
});
```

Update the test script to include both test files:

```json
"test": "TZ=UTC node --test test/*.test.ts"
```

Run `npm test` from `modules/nixos/vasher-dashboard`. Expected result: FAIL because the helper and event type do not exist.

- [ ] **Step 2: Add event types and snapshot loading**

Create `src/event-text.ts` with these exported types and helper:

```typescript
export type MonitorEvent = {
  id: string;
  timestamp: string;
  revision: string;
  type: string;
  severity: "info" | "warning" | "error";
  reason: string | null;
  metrics: Record<string, number | string>;
  action: string | null;
  summary?: string;
  inferenceError?: string;
};

export type EventText = {
  title: string;
  detail: string;
  summary: string | null;
};

export function renderEventText(event: MonitorEvent): EventText {
  return {
    title: event.type.replaceAll("-", " ").toUpperCase(),
    detail: [event.reason, event.action].filter(Boolean).join(" / ") || "observation",
    summary: event.summary ?? null,
  };
}
```


Extend the existing prebuild status unions:

```typescript
type State = "idle" | "preparing" | "building" | "success" | "failed" | "stale";
type Mode = "refresh" | "candidate" | "retry";
```

Add this first branch to `statusCopy`:

```typescript
if (status.state === "preparing") return "Updating candidate inputs before the build.";
```

Import `MonitorEvent` and `renderEventText` into `main.tsx`.

Add `events: MonitorEvent[]` to `Snapshot` and `emptySnapshot`. Fetch `/api/events.json` in the existing `Promise.all` call.

- [ ] **Step 3: Render the newest-first timeline**

Destructure `events` from `useSnapshot()`. Insert this panel before the recent runs panel:

```tsx
<article className="panel full">
  <h2>Monitor events</h2>
  <ol className="events">
    {events.length === 0 ? (
      <li>No monitor events recorded yet.</li>
    ) : events.map((event) => {
      const text = renderEventText(event);
      return (
        <li key={event.id} className={`event ${event.severity}`}>
          <time>{formatTimestamp(event.timestamp)}</time>
          <div>
            <p className="event-title">{text.title}</p>
            <p className="event-detail">{text.detail}</p>
            {text.summary ? <p className="event-summary">{text.summary}</p> : null}
            {event.inferenceError ? <p className="event-error">Inference error: {event.inferenceError}</p> : null}
          </div>
        </li>
      );
    })}
  </ol>
</article>
```

React text nodes provide the required HTML escaping. Do not use `dangerouslySetInnerHTML`.

- [ ] **Step 4: Add timeline styles**

Add a blue information color and list styles without changing the existing layout:

```css
:root { --blue: #89b4fa; }
.events { margin: 0; padding: 0; list-style: none; }
.event { display: grid; grid-template-columns: 12rem 1fr; gap: 1rem; border-bottom: 1px solid var(--surface); padding: .9rem 1rem; }
.event:last-child { border-bottom: 0; }
.event-title { margin: 0; color: var(--blue); font: 700 .78rem ui-monospace, monospace; }
.event.warning .event-title { color: var(--peach); }
.event.error .event-title, .event-error { color: var(--red); }
.event-detail { margin: .25rem 0 0; color: var(--subtext); font: .75rem ui-monospace, monospace; }
.event-summary { margin: .55rem 0 0; }
.event-error { margin: .55rem 0 0; font: .75rem ui-monospace, monospace; }
```


Extend the existing build-state selectors:

```css
.pulse.preparing .dot, .pulse.building .dot { background: var(--peach); box-shadow: 0 0 0 .3rem color-mix(in srgb, var(--peach), transparent 72%); }
.preparing, .building { color: var(--peach); }
```
Add `.event { grid-template-columns: 1fr; }` to the existing mobile media query.

- [ ] **Step 5: Run dashboard tests and build**

Run from `modules/nixos/vasher-dashboard`:

```bash
npm test
npm run build
```

Expected result: all Node tests pass, TypeScript reports no errors, and Vite produces `dist/`.

Update `npmDepsHash` in `modules/nixos/vasher-prebuild.nix` only if the lock file changes. This task adds no package dependency, so the hash normally stays unchanged.

- [ ] **Step 6: Commit the ledger timeline**

```bash
git add modules/nixos/vasher-dashboard modules/nixos/vasher-prebuild.nix
git commit -m "feat(vasher): show prebuild monitor events"
```

---

### Task 7: Verify, Deploy, and Exercise the Monitor

**Files:**
- Modify only if verification finds a source defect in the files from Tasks 1 through 6.

**Interfaces:**
- Consumes: All committed monitor, prebuild, service, and dashboard changes.
- Produces: A deployed monitor, live ledger route, and evidence for each safety boundary.

- [ ] **Step 1: Run every focused local test once**

Run:

```bash
bash scripts/tests/test-vasher-prebuild-gc.sh
bash scripts/tests/test-vasher-prebuild-retry.sh
python3 -m unittest scripts/tests/test-vasher-prebuild-monitor.py -v
bash scripts/tests/test-vasher-monitor-closure.sh
npm test --prefix modules/nixos/vasher-dashboard
npm run build --prefix modules/nixos/vasher-dashboard
nix build --no-link .#nixosConfigurations.vasher.config.system.build.toplevel
```

Expected result: every command exits `0`.

- [ ] **Step 2: Inspect the final change set for scope**

Run:

```bash
git diff --stat origin/master...HEAD
git diff --check origin/master...HEAD
```

Expected result: only the files named in this plan and the approved specification differ. The whitespace check prints no output.

- [ ] **Step 3: Push the implementation commits**

```bash
git push origin master
```

Expected result: `origin/master` advances to the local implementation head.

- [ ] **Step 4: Deploy the Vasher configuration**

Run the normal remote switch through the existing operator SSH path:

```bash
ssh root@vasher nixos-rebuild switch --refresh --flake github:rykugur/dotfiles#vasher
```

This operator command is outside the monitor. The deployed monitor itself has no SSH path.

Expected result: the switch exits `0` and starts `vasher-prebuild-monitor.service`.

- [ ] **Step 5: Make sure that service hardening and routing are active**

Run:

```bash
ssh root@vasher systemctl is-active vasher-prebuild-monitor.service
curl --fail --silent --show-error https://vasher-ledger.k8s.local.ryk.sh/api/events.json
```

Expected result: systemd prints `active`, and the API returns a JSON array.

Run:

```bash
ssh root@vasher systemctl show vasher-prebuild-monitor.service \
  --property=IPAddressDeny,InaccessiblePaths,ProtectHome,ProtectSystem,CapabilityBoundingSet
```

Expected result: the private-address deny list and filesystem restrictions match Task 5.

- [ ] **Step 6: Verify the automatic recovery contract**

Run:

```bash
python3 -m unittest scripts/tests/test-vasher-prebuild-monitor.py -v
```

Expected result: the output includes passing cases for the threshold timers, action order, durable retry count, and final stop.

Do not force a resource threshold on the live Vasher host.

- [ ] **Step 7: Verify model-output escaping in the real frontend**

Open the live ledger with the browser tool. Intercept only `/api/events.json` inside that browser run and return one fixture event.

Use this summary:

```text
<script>globalThis.vasherMonitorInjected = true</script>
```

Make sure that the literal text appears in the event timeline. Evaluate `globalThis.vasherMonitorInjected` in the page.

Expected result: the value is `undefined`. End request interception without changing the live event file.

- [ ] **Step 8: Verify normal live observation without starting a build**

Read the live monitor journal and event endpoint. Make sure that the monitor samples safely while both prebuild units are inactive.

Expected result: no recovery action occurs, no inference request occurs, and the monitor stays active.

- [ ] **Step 9: Record final verification**

Record the exact passing commands, deployed commit, active service state, closure result, and browser result in the final response.

Do not claim that a real unsafe build was stopped unless a real threshold crossed during observation.
