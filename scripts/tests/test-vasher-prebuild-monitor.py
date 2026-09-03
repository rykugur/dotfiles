#!/usr/bin/env python3
from __future__ import annotations

import dataclasses
import importlib.util
import json
import os
import stat
import subprocess
import sys
import tempfile
import unittest
from dataclasses import asdict
from pathlib import Path

MODULE_PATH = Path(__file__).parents[2] / "modules/nixos/vasher-prebuild-monitor.py"
SPEC = importlib.util.spec_from_file_location("vasher_prebuild_monitor", MODULE_PATH)
assert SPEC is not None
assert SPEC.loader is not None
monitor = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = monitor
SPEC.loader.exec_module(monitor)


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


class ThresholdEvaluationTests(unittest.TestCase):
    def test_memory_threshold_requires_120_seconds(self):
        state = monitor.MonitorState.for_revision("1" * 40, "2" * 40)
        state, decision = monitor.evaluate(
            state, sample(0, mem_available=700 * monitor.MIB)
        )
        self.assertIsNone(decision)
        state, decision = monitor.evaluate(
            state, sample(119, mem_available=700 * monitor.MIB)
        )
        self.assertIsNone(decision)
        state, decision = monitor.evaluate(
            state, sample(120, mem_available=700 * monitor.MIB)
        )
        self.assertEqual(decision, monitor.Decision("stop", "memory"))

    def test_safe_sample_clears_memory_timer(self):
        state = monitor.MonitorState.for_revision("1" * 40, "2" * 40)
        state, _ = monitor.evaluate(
            state, sample(0, swap_free=200 * monitor.MIB)
        )
        state, _ = monitor.evaluate(state, sample(90))
        self.assertIsNone(state.memory_since)
        state, decision = monitor.evaluate(
            state, sample(180, swap_free=200 * monitor.MIB)
        )
        self.assertIsNone(decision)
        self.assertEqual(state.memory_since, 180)

    def test_disk_threshold_requires_60_seconds(self):
        state = monitor.MonitorState.for_revision("1" * 40, "2" * 40)
        state, _ = monitor.evaluate(state, sample(0, disk_free=4 * monitor.GIB))
        state, decision = monitor.evaluate(
            state, sample(60, disk_free=4 * monitor.GIB)
        )
        self.assertEqual(decision, monitor.Decision("stop", "disk"))

    def test_log_or_cpu_activity_prevents_stall(self):
        state = monitor.MonitorState.for_revision("1" * 40, "2" * 40)
        state, _ = monitor.evaluate(state, sample(0))
        state, _ = monitor.evaluate(
            state, sample(900, log_size=101, combined_cpu_seconds=901)
        )
        state, decision = monitor.evaluate(
            state, sample(1800, log_size=101, combined_cpu_seconds=910)
        )
        self.assertIsNone(decision)

    def test_cpu_activity_resets_stall_timer(self):
        state = monitor.MonitorState.for_revision("1" * 40, "2" * 40)
        state, _ = monitor.evaluate(state, sample(0, combined_cpu_seconds=0))
        state, decision = monitor.evaluate(
            state, sample(1800, combined_cpu_seconds=10)
        )
        self.assertIsNone(decision)
        self.assertEqual(state.stall_since, 1800)
        self.assertEqual(state.stall_cpu_start, 10)

    def test_idle_build_stops_after_30_minutes(self):
        state = monitor.MonitorState.for_revision("1" * 40, "2" * 40)
        state, _ = monitor.evaluate(state, sample(0, combined_cpu_seconds=0))
        state, decision = monitor.evaluate(
            state, sample(1800, combined_cpu_seconds=9)
        )
        self.assertEqual(decision, monitor.Decision("stop", "stall"))

    def test_second_unsafe_condition_never_retries(self):
        state = monitor.MonitorState.for_revision("1" * 40, "2" * 40)
        state.retry_count = 1
        state.phase = "retrying"
        state, decision = monitor.evaluate(
            state, sample(0, mem_available=700 * monitor.MIB)
        )
        self.assertIsNone(decision)
        state, decision = monitor.evaluate(
            state, sample(120, mem_available=700 * monitor.MIB)
        )
        self.assertEqual(decision, monitor.Decision("stop-final", "memory"))


class DurableStateTests(unittest.TestCase):
    def test_threshold_timer_persists_across_reload(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "state.json"
            state = monitor.MonitorState.for_revision("1" * 40, "2" * 40)
            state, _ = monitor.evaluate(
                state, sample(10, mem_available=700 * monitor.MIB)
            )
            monitor.atomic_json(path, asdict(state))

            reloaded = monitor.load_state(path, "1" * 40, "2" * 40)
            reloaded, decision = monitor.evaluate(
                reloaded, sample(130, mem_available=700 * monitor.MIB)
            )

            self.assertEqual(decision, monitor.Decision("stop", "memory"))

    def test_durable_reload_preserves_later_task_fields(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "state.json"
            state = monitor.MonitorState(
                base_revision="1" * 40,
                revision="2" * 40,
                phase="retrying",
                retry_count=1,
                memory_since=12.0,
                last_terminal_at="2026-09-02T22:01:00Z",
                boot_id="boot-123",
                disk_since=24.0,
                nix_safe_since=60.0,
                stall_since=36.0,
                stall_cpu_start=48.0,
                last_log_size=1234,
                cleaning_since=90.0,
            )
            monitor.atomic_json(path, asdict(state))

            reloaded = monitor.load_state(path, "1" * 40, "2" * 40)

            self.assertEqual(reloaded, state)
            self.assertEqual(reloaded.retry_count, 1)
            self.assertEqual(reloaded.last_terminal_at, "2026-09-02T22:01:00Z")
            self.assertEqual(reloaded.boot_id, "boot-123")
            self.assertEqual(reloaded.nix_safe_since, 60.0)

    def test_different_revision_resets_state(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "state.json"
            state = monitor.MonitorState.for_revision("1" * 40, "2" * 40)
            state.retry_count = 1
            state.memory_since = 10.0
            state.last_terminal_at = "2026-09-02T22:01:00Z"
            monitor.atomic_json(path, asdict(state))

            reloaded = monitor.load_state(path, "1" * 40, "3" * 40)

            self.assertEqual(
                reloaded,
                monitor.MonitorState.for_revision("1" * 40, "3" * 40),
            )

    def test_state_and_retry_default_to_private_atomic_mode(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            for name in ("state.json", "retry.json"):
                with self.subTest(name=name):
                    path = root / name
                    monitor.atomic_json(path, {"name": name})
                    self.assertEqual(stat.S_IMODE(path.stat().st_mode), 0o600)
                    self.assertFalse(path.with_name(f".{path.name}.tmp").exists())

    def test_ledger_mode_is_world_readable(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "events.json"
            monitor.append_event(path, {"id": 1})

            self.assertEqual(stat.S_IMODE(path.stat().st_mode), 0o644)
            self.assertFalse(path.with_name(f".{path.name}.tmp").exists())

    def test_ledger_retains_exactly_100_newest_events(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "events.json"
            for event_id in range(105):
                monitor.append_event(path, {"id": event_id})

            events = monitor.json.loads(path.read_text())

            self.assertEqual(len(events), 100)
            self.assertEqual(
                [event["id"] for event in events], list(range(104, 4, -1))
            )

def write_detached_worktree(
    root: Path, revision: str | None, *, via_gitdir: bool = True
) -> Path:
    worktree = root / "candidate"
    worktree.mkdir(parents=True, exist_ok=True)
    if via_gitdir:
        gitdir = root / "gitdir"
        gitdir.mkdir(parents=True, exist_ok=True)
        if revision is not None:
            (gitdir / "HEAD").write_text(f"{revision}\n")
        else:
            (gitdir / "HEAD").unlink(missing_ok=True)

        (worktree / ".git").write_text(f"gitdir: {gitdir}\n")
    else:
        git = worktree / ".git"
        git.mkdir(parents=True, exist_ok=True)
        if revision is not None:
            (git / "HEAD").write_text(f"{revision}\n")
        else:
            (git / "HEAD").unlink(missing_ok=True)

    return worktree


class FakeRunner:
    def __init__(
        self,
        active: dict[str, bool] | None = None,
        cleanup_result: int = 0,
        properties: dict[str, dict[str, str]] | None = None,
        worktree_head: str | None = "2" * 40,
    ) -> None:
        self.calls: list[tuple[str, ...]] = []
        self.active = dict(active or {})
        self.cleanup_result = cleanup_result
        self.properties = properties or {}
        self.worktree_head = worktree_head

    def sleep(self, _seconds: float) -> None:
        return None

    def run(
        self,
        arguments: list[str],
        *,
        check: bool = True,
    ) -> subprocess.CompletedProcess[str]:
        recorded = tuple(
            Path(arguments[0]).name if index == 0 else argument
            for index, argument in enumerate(arguments)
        )
        self.calls.append(recorded)
        command = recorded[1:]
        stdout = ""
        returncode = 0
        if command[:2] == ("stop",) or (len(command) >= 2 and command[0] == "stop"):
            unit = command[1]
            self.active[unit] = False
        elif command == ("start", "vasher-prebuild-cleanup.service"):
            returncode = self.cleanup_result
        elif command[:1] == ("show",):
            unit = command[1]
            values = self.properties.get(unit, {})
            stdout = "".join(f"{name}={value}\n" for name, value in values.items())
        elif recorded[:1] == ("git",) and recorded[-2:] == ("rev-parse", "HEAD"):
            if self.worktree_head is None:
                returncode = 128
            else:
                stdout = f"{self.worktree_head}\n"
        result = subprocess.CompletedProcess(arguments, returncode, stdout, "")
        if check and returncode:
            raise subprocess.CalledProcessError(returncode, arguments, stdout, "")
        return result


class SequenceReader:
    def __init__(self, samples: list[monitor.Sample]) -> None:
        self._samples = list(samples)

    def sample(self) -> monitor.Sample | None:
        if not self._samples:
            return None
        return self._samples.pop(0)


class RecoveryControllerTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        root = Path(self.directory.name)
        self.state_path = root / "state.json"
        self.events_path = root / "events.json"
        self.retry_path = root / "retry.json"
        self.unsafe_sample = sample(90, nix_memory=256 * monitor.MIB)
        self._patch_worktree("2" * 40)

    def _patch_worktree(self, revision: str | None, *, via_gitdir: bool = True) -> Path:
        worktree = write_detached_worktree(
            Path(self.directory.name), revision, via_gitdir=via_gitdir
        )
        original = monitor.CANDIDATE_WORKTREE
        self.addCleanup(setattr, monitor, "CANDIDATE_WORKTREE", original)
        monitor.CANDIDATE_WORKTREE = str(worktree)
        return worktree


    def tearDown(self):
        self.directory.cleanup()

    def test_recovery_stops_cleans_then_retries(self):
        runner = FakeRunner(
            active={"vasher-prebuild-candidate.service": True},
            cleanup_result=0,
        )
        controller = monitor.Controller(
            runner, self.state_path, self.events_path, self.retry_path
        )
        controller.recover(self.unsafe_sample, monitor.Decision("stop", "memory"))
        self.assertEqual(
            runner.calls,
            [
                ("systemctl", "stop", "vasher-prebuild-candidate.service"),
                ("systemctl", "start", "vasher-prebuild-cleanup.service"),
                ("systemctl", "start", "--no-block", "vasher-prebuild-retry.service"),
            ],
        )

    def test_failed_precondition_records_needs_attention(self):
        runner = FakeRunner(
            active={"vasher-prebuild-candidate.service": True},
            cleanup_result=0,
        )
        controller = monitor.Controller(
            runner, self.state_path, self.events_path, self.retry_path
        )
        controller.recover(
            dataclasses.replace(self.unsafe_sample, disk_free=9 * monitor.GIB),
            monitor.Decision("stop", "disk"),
        )
        self.assertNotIn(
            ("systemctl", "start", "--no-block", "vasher-prebuild-retry.service"),
            runner.calls,
        )
        self.assertEqual(controller.state.phase, "needs-attention")

    def test_retry_count_is_saved_before_retry_start(self):
        runner = FakeRunner(
            active={"vasher-prebuild-candidate.service": True},
            cleanup_result=0,
        )
        controller = monitor.Controller(
            runner, self.state_path, self.events_path, self.retry_path
        )
        controller.recover(self.unsafe_sample, monitor.Decision("stop", "memory"))
        saved = json.loads(self.state_path.read_text())
        self.assertEqual(saved["retry_count"], 1)
        self.assertEqual(saved["phase"], "retrying")

    def test_host_reboot_during_recovery_requires_attention(self):
        runner = FakeRunner()
        state = monitor.MonitorState.for_revision("1" * 40, "2" * 40)
        state.phase = "cleaning"
        state.boot_id = "old-boot"
        monitor.atomic_json(self.state_path, dataclasses.asdict(state))
        controller = monitor.Controller(
            runner,
            self.state_path,
            self.events_path,
            self.retry_path,
            boot_id="new-boot",
        )
        self.assertEqual(controller.state.phase, "needs-attention")
        self.assertNotIn(
            ("systemctl", "start", "--no-block", "vasher-prebuild-retry.service"),
            runner.calls,
        )

    def test_stop_final_stops_without_cleanup_or_retry(self):
        runner = FakeRunner(
            active={"vasher-prebuild-retry.service": True},
        )
        controller = monitor.Controller(
            runner, self.state_path, self.events_path, self.retry_path
        )
        final_sample = sample(
            90,
            active_unit="vasher-prebuild-retry.service",
            mode="retry",
        )
        controller.recover(final_sample, monitor.Decision("stop-final", "memory"))
        self.assertEqual(
            runner.calls,
            [
                ("systemctl", "stop", "vasher-prebuild-retry.service"),
            ],
        )
        self.assertEqual(controller.state.phase, "needs-attention")

    def test_recover_retries_after_low_memory_recovers(self):
        runner = FakeRunner(
            active={"vasher-prebuild-candidate.service": True},
        )
        low = sample(
            90,
            mem_available=500 * monitor.MIB,
            nix_memory=256 * monitor.MIB,
        )
        self.assertLess(low.mem_available, monitor.MEMORY_LIMIT)
        later = [
            sample(
                120,
                mem_available=4 * monitor.GIB,
                nix_memory=256 * monitor.MIB,
                active_unit=None,
            ),
            sample(
                150,
                mem_available=4 * monitor.GIB,
                nix_memory=256 * monitor.MIB,
                active_unit=None,
            ),
            sample(
                180,
                mem_available=4 * monitor.GIB,
                nix_memory=256 * monitor.MIB,
                active_unit=None,
            ),
        ]
        controller = monitor.Controller(
            runner,
            self.state_path,
            self.events_path,
            self.retry_path,
            reader=SequenceReader(later),
        )
        controller.recover(low, monitor.Decision("stop", "memory"))
        self.assertEqual(
            runner.calls,
            [
                ("systemctl", "stop", "vasher-prebuild-candidate.service"),
                ("systemctl", "start", "vasher-prebuild-cleanup.service"),
                ("systemctl", "start", "--no-block", "vasher-prebuild-retry.service"),
            ],
        )
        self.assertEqual(controller.state.phase, "retrying")

    def test_observe_resumes_stopping_without_active_unit(self):
        runner = FakeRunner()
        state = monitor.MonitorState.for_revision("1" * 40, "2" * 40)
        state.phase = "stopping"
        state.boot_id = "same-boot"
        monitor.atomic_json(self.state_path, dataclasses.asdict(state))
        controller = monitor.Controller(
            runner,
            self.state_path,
            self.events_path,
            self.retry_path,
            boot_id="same-boot",
        )
        idle = sample(90, active_unit=None, nix_memory=256 * monitor.MIB)
        controller.observe(idle)
        self.assertEqual(
            runner.calls,
            [
                ("systemctl", "start", "vasher-prebuild-cleanup.service"),
                ("systemctl", "start", "--no-block", "vasher-prebuild-retry.service"),
            ],
        )
        self.assertEqual(controller.state.phase, "retrying")

    def test_observe_resumes_retrying_without_active_unit(self):
        runner = FakeRunner()
        state = monitor.MonitorState.for_revision("1" * 40, "2" * 40)
        state.phase = "retrying"
        state.retry_count = 1
        state.boot_id = "same-boot"
        monitor.atomic_json(self.state_path, dataclasses.asdict(state))
        controller = monitor.Controller(
            runner,
            self.state_path,
            self.events_path,
            self.retry_path,
            boot_id="same-boot",
        )
        idle = sample(90, active_unit=None)
        controller.observe(idle)
        self.assertEqual(
            runner.calls,
            [
                ("systemctl", "start", "--no-block", "vasher-prebuild-retry.service"),
            ],
        )
        self.assertEqual(controller.state.phase, "retrying")
        saved = json.loads(self.retry_path.read_text())
        self.assertEqual(saved["baseRevision"], "1" * 40)
        self.assertEqual(saved["revision"], "2" * 40)


    def test_observe_skips_sigterm_failed_status_during_recovery(self):
        runner = FakeRunner()
        state = monitor.MonitorState.for_revision("1" * 40, "2" * 40)
        state.phase = "stopping"
        state.boot_id = "same-boot"
        monitor.atomic_json(self.state_path, dataclasses.asdict(state))
        controller = monitor.Controller(
            runner,
            self.state_path,
            self.events_path,
            self.retry_path,
            boot_id="same-boot",
        )
        sigterm_failed = sample(
            90,
            active_unit=None,
            status_state="failed",
            status_updated_at="2026-09-02T22:03:00+00:00",
            exit_code=143,
            nix_memory=256 * monitor.MIB,
        )
        controller.observe(sigterm_failed)
        self.assertNotEqual(controller.state.phase, "complete")
        self.assertEqual(controller.state.phase, "retrying")
        self.assertEqual(
            runner.calls,
            [
                ("systemctl", "start", "vasher-prebuild-cleanup.service"),
                ("systemctl", "start", "--no-block", "vasher-prebuild-retry.service"),
            ],
        )
        try:
            events = json.loads(self.events_path.read_text())
        except FileNotFoundError:
            events = []
        self.assertFalse(any(event["type"] == "build-failed" for event in events))


    def test_observe_retrying_success_marks_complete(self):
        runner = FakeRunner()
        state = monitor.MonitorState.for_revision("1" * 40, "2" * 40)
        state.phase = "retrying"
        state.retry_count = 1
        state.boot_id = "same-boot"
        monitor.atomic_json(self.state_path, dataclasses.asdict(state))
        controller = monitor.Controller(
            runner,
            self.state_path,
            self.events_path,
            self.retry_path,
            boot_id="same-boot",
        )
        finished = sample(
            90,
            active_unit=None,
            status_state="success",
            status_updated_at="2026-09-02T22:10:00+00:00",
            exit_code=0,
            mode="retry",
        )
        controller.observe(finished)
        self.assertEqual(controller.state.phase, "complete")
        self.assertNotIn(
            ("systemctl", "start", "--no-block", "vasher-prebuild-retry.service"),
            runner.calls,
        )
        events = json.loads(self.events_path.read_text())
        self.assertTrue(any(event["type"] == "build-succeeded" for event in events))

    def test_observe_retrying_failed_records_failure(self):
        runner = FakeRunner()
        state = monitor.MonitorState.for_revision("1" * 40, "2" * 40)
        state.phase = "retrying"
        state.retry_count = 1
        state.boot_id = "same-boot"
        monitor.atomic_json(self.state_path, dataclasses.asdict(state))
        controller = monitor.Controller(
            runner,
            self.state_path,
            self.events_path,
            self.retry_path,
            boot_id="same-boot",
        )
        finished = sample(
            90,
            active_unit=None,
            status_state="failed",
            status_updated_at="2026-09-02T22:10:00+00:00",
            exit_code=1,
            mode="retry",
        )
        controller.observe(finished)
        self.assertEqual(controller.state.phase, "complete")
        self.assertNotIn(
            ("systemctl", "start", "--no-block", "vasher-prebuild-retry.service"),
            runner.calls,
        )
        events = json.loads(self.events_path.read_text())
        failed = next(event for event in events if event["type"] == "build-failed")
        self.assertEqual(failed["exitCode"], 1)

    def test_observe_retrying_leftover_candidate_sigterm_resumes_retry(self):
        runner = FakeRunner()
        state = monitor.MonitorState.for_revision("1" * 40, "2" * 40)
        state.phase = "retrying"
        state.retry_count = 1
        state.boot_id = "same-boot"
        monitor.atomic_json(self.state_path, dataclasses.asdict(state))
        controller = monitor.Controller(
            runner,
            self.state_path,
            self.events_path,
            self.retry_path,
            boot_id="same-boot",
        )
        leftover = sample(
            90,
            active_unit=None,
            status_state="failed",
            status_updated_at="2026-09-02T22:03:00+00:00",
            exit_code=143,
            mode="candidate",
        )
        controller.observe(leftover)
        self.assertNotEqual(controller.state.phase, "complete")
        self.assertEqual(controller.state.phase, "retrying")
        self.assertEqual(
            runner.calls,
            [
                ("systemctl", "start", "--no-block", "vasher-prebuild-retry.service"),
            ],
        )

    def test_mismatched_worktree_does_not_consume_retry(self):
        self._patch_worktree("3" * 40)
        runner = FakeRunner(
            active={"vasher-prebuild-candidate.service": True},
            worktree_head="2" * 40,
        )
        controller = monitor.Controller(
            runner, self.state_path, self.events_path, self.retry_path
        )
        controller.recover(self.unsafe_sample, monitor.Decision("stop", "memory"))
        self.assertEqual(controller.state.phase, "needs-attention")
        self.assertEqual(controller.state.retry_count, 0)
        saved = json.loads(self.state_path.read_text())
        self.assertEqual(saved["retry_count"], 0)
        self.assertNotIn(
            ("systemctl", "start", "--no-block", "vasher-prebuild-retry.service"),
            runner.calls,
        )
        self.assertFalse(any(call[:1] == ("git",) for call in runner.calls))

    def test_unreadable_worktree_head_does_not_consume_retry(self):
        self._patch_worktree(None)
        runner = FakeRunner(
            active={"vasher-prebuild-candidate.service": True},
            worktree_head="2" * 40,
        )
        controller = monitor.Controller(
            runner, self.state_path, self.events_path, self.retry_path
        )
        controller.recover(self.unsafe_sample, monitor.Decision("stop", "memory"))
        self.assertEqual(controller.state.phase, "needs-attention")
        self.assertEqual(controller.state.retry_count, 0)
        saved = json.loads(self.state_path.read_text())
        self.assertEqual(saved["retry_count"], 0)
        self.assertNotIn(
            ("systemctl", "start", "--no-block", "vasher-prebuild-retry.service"),
            runner.calls,
        )
        self.assertFalse(any(call[:1] == ("git",) for call in runner.calls))

    def test_matching_detached_head_file_allows_retry(self):
        self._patch_worktree("2" * 40)
        runner = FakeRunner(
            active={"vasher-prebuild-candidate.service": True},
            worktree_head="3" * 40,
        )
        controller = monitor.Controller(
            runner, self.state_path, self.events_path, self.retry_path
        )
        controller.recover(self.unsafe_sample, monitor.Decision("stop", "memory"))
        self.assertEqual(controller.state.phase, "retrying")
        self.assertEqual(controller.state.retry_count, 1)
        self.assertIn(
            ("systemctl", "start", "--no-block", "vasher-prebuild-retry.service"),
            runner.calls,
        )
        self.assertFalse(any(call[:1] == ("git",) for call in runner.calls))


    def test_cleaning_timeout_uses_persisted_start(self):
        runner = FakeRunner()
        state = monitor.MonitorState.for_revision("1" * 40, "2" * 40)
        state.phase = "cleaning"
        state.boot_id = "same-boot"
        state.nix_safe_since = None
        state.cleaning_since = 0.0
        monitor.atomic_json(self.state_path, dataclasses.asdict(state))
        controller = monitor.Controller(
            runner,
            self.state_path,
            self.events_path,
            self.retry_path,
            boot_id="same-boot",
        )
        still_high = sample(
            600,
            active_unit=None,
            nix_memory=3 * monitor.GIB,
        )
        controller.observe(still_high)
        self.assertEqual(controller.state.phase, "needs-attention")
        self.assertNotIn(
            ("systemctl", "start", "--no-block", "vasher-prebuild-retry.service"),
            runner.calls,
        )


class SamplingConversionTests(unittest.TestCase):
    def test_read_meminfo_converts_kib_to_bytes(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "meminfo"
            path.write_text(
                "MemTotal:        8388608 kB\n"
                "MemAvailable:    2097152 kB\n"
                "SwapFree:         1048576 kB\n"
            )
            values = monitor.read_meminfo(path)
            self.assertEqual(values["MemAvailable"], 2097152 * 1024)
            self.assertEqual(values["SwapFree"], 1048576 * 1024)

    def test_read_memory_pressure_uses_full_avg10(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "pressure"
            path.write_text(
                "some avg10=0.12 avg60=0.08 avg300=0.04 total=10\n"
                "full avg10=2.50 avg60=1.25 avg300=0.75 total=20\n"
            )
            self.assertEqual(monitor.read_memory_pressure(path), 2.50)

    def test_system_reader_sample_conversions(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            meminfo = root / "meminfo"
            pressure = root / "pressure"
            status = root / "status.json"
            log_path = root / "current.log"
            meminfo.write_text(
                "MemAvailable:    3145728 kB\n"
                "SwapFree:         1572864 kB\n"
            )
            pressure.write_text("full avg10=3.25 avg60=0.00 avg300=0.00 total=1\n")
            status.write_text(
                json.dumps(
                    {
                        "state": "building",
                        "mode": "candidate",
                        "updatedAt": "2026-09-02T22:00:00Z",
                        "baseRevision": "1" * 40,
                        "revision": "2" * 40,
                    }
                )
            )
            log_path.write_bytes(b"hello world")
            runner = FakeRunner(
                active={"vasher-prebuild-candidate.service": True},
                properties={
                    "vasher-prebuild-candidate.service": {
                        "ActiveState": "active",
                        "CPUUsageNSec": "4000000000",
                    },
                    "vasher-prebuild-retry.service": {
                        "ActiveState": "inactive",
                        "CPUUsageNSec": "0",
                    },
                    "nix-daemon.service": {
                        "MemoryCurrent": str(512 * monitor.MIB),
                        "CPUUsageNSec": "2500000000",
                    },
                },
            )

            def fake_statvfs(_path: str) -> os.statvfs_result:
                return os.statvfs_result((4096, 4096, 0, 0, 5 * 1024 * 1024, 0, 0, 0, 0, 0))

            reader = monitor.SystemReader(
                runner,
                meminfo_path=meminfo,
                pressure_path=pressure,
                status_path=status,
                log_path=log_path,
                statvfs=fake_statvfs,
                now=lambda: 42.0,
            )
            observed = reader.sample()
            self.assertIsNotNone(observed)
            assert observed is not None
            self.assertEqual(observed.at, 42.0)
            self.assertEqual(
                observed.active_unit, "vasher-prebuild-candidate.service"
            )
            self.assertEqual(observed.mode, "candidate")
            self.assertEqual(observed.status_state, "building")
            self.assertEqual(observed.status_updated_at, "2026-09-02T22:00:00Z")
            self.assertEqual(observed.base_revision, "1" * 40)
            self.assertEqual(observed.revision, "2" * 40)
            self.assertEqual(observed.mem_available, 3145728 * 1024)
            self.assertEqual(observed.swap_free, 1572864 * 1024)
            self.assertEqual(observed.memory_pressure_full, 3.25)
            self.assertEqual(observed.disk_free, 5 * 1024 * 1024 * 4096)
            self.assertEqual(observed.nix_memory, 512 * monitor.MIB)
            self.assertEqual(observed.combined_cpu_seconds, 6.5)
            self.assertEqual(observed.log_size, 11)


    def test_system_reader_treats_activating_as_running(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            meminfo = root / "meminfo"
            pressure = root / "pressure"
            status = root / "status.json"
            meminfo.write_text("MemAvailable: 1024 kB\nSwapFree: 1024 kB\n")
            pressure.write_text("full avg10=0.00 avg60=0.00 avg300=0.00 total=0\n")
            status.write_text(
                json.dumps(
                    {
                        "state": "building",
                        "mode": "candidate",
                        "updatedAt": "2026-09-02T22:00:00Z",
                        "baseRevision": "1" * 40,
                        "revision": "2" * 40,
                    }
                )
            )
            runner = FakeRunner(
                properties={
                    "vasher-prebuild-candidate.service": {
                        "ActiveState": "activating",
                        "CPUUsageNSec": "1000000000",
                    },
                    "vasher-prebuild-retry.service": {
                        "ActiveState": "inactive",
                        "CPUUsageNSec": "0",
                    },
                    "nix-daemon.service": {
                        "MemoryCurrent": "0",
                        "CPUUsageNSec": "0",
                    },
                }
            )
            reader = monitor.SystemReader(
                runner,
                meminfo_path=meminfo,
                pressure_path=pressure,
                status_path=status,
                log_path=root / "missing.log",
                statvfs=lambda _path: os.statvfs_result(
                    (4096, 4096, 0, 0, 1, 0, 0, 0, 0, 0)
                ),
                now=lambda: 1.0,
            )
            observed = reader.sample()
            self.assertIsNotNone(observed)
            assert observed is not None
            self.assertEqual(
                observed.active_unit, "vasher-prebuild-candidate.service"
            )
            self.assertEqual(observed.combined_cpu_seconds, 1.0)

    def test_terminal_status_clears_active_unit(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            meminfo = root / "meminfo"
            pressure = root / "pressure"
            status = root / "status.json"
            meminfo.write_text("MemAvailable: 1024 kB\nSwapFree: 1024 kB\n")
            pressure.write_text("full avg10=0.00 avg60=0.00 avg300=0.00 total=0\n")
            status.write_text(
                json.dumps(
                    {
                        "state": "success",
                        "mode": "candidate",
                        "updatedAt": "2026-09-02T22:05:00Z",
                        "baseRevision": "1" * 40,
                        "revision": "2" * 40,
                        "exitCode": 0,
                    }
                )
            )
            runner = FakeRunner(
                properties={
                    "vasher-prebuild-candidate.service": {"ActiveState": "active"},
                    "vasher-prebuild-retry.service": {"ActiveState": "inactive"},
                    "nix-daemon.service": {"MemoryCurrent": "0", "CPUUsageNSec": "0"},
                }
            )
            reader = monitor.SystemReader(
                runner,
                meminfo_path=meminfo,
                pressure_path=pressure,
                status_path=status,
                log_path=root / "missing.log",
                statvfs=lambda _path: os.statvfs_result((4096, 4096, 0, 0, 1, 0, 0, 0, 0, 0)),
                now=lambda: 1.0,
            )
            observed = reader.sample()
            self.assertIsNotNone(observed)
            assert observed is not None
            self.assertIsNone(observed.active_unit)
            self.assertEqual(observed.status_state, "success")
            self.assertEqual(observed.log_size, 0)

    def test_invalid_revision_raises_invalid_status(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            status = root / "status.json"
            status.write_text(
                json.dumps(
                    {
                        "state": "building",
                        "mode": "candidate",
                        "updatedAt": "2026-09-02T22:00:00Z",
                        "baseRevision": "not-a-revision",
                        "revision": "2" * 40,
                    }
                )
            )
            reader = monitor.SystemReader(
                FakeRunner(),
                status_path=status,
                meminfo_path=root / "meminfo",
                pressure_path=root / "pressure",
            )
            with self.assertRaises(monitor.InvalidStatus):
                reader.sample()


class FakeTransport:
    def __init__(self, payload: dict[str, object]) -> None:
        self.payload = payload
        self.requests: list[object] = []

    def send(self, request: object) -> dict[str, object]:
        self.requests.append(request)
        return self.payload


class FakeModel:
    def __init__(self, text: str) -> None:
        self.text = text
        self.runner_calls_at_request: list[tuple[str, ...]] | None = None
        self.requests = 0
        self.recovery_in_progress_at_request: list[bool] = []
        self._runner: FakeRunner | None = None
        self._controller: object | None = None

    def summarize(self, evidence: str) -> str:
        self.requests += 1
        if self._runner is not None:
            self.runner_calls_at_request = list(self._runner.calls)
        if self._controller is not None:
            self.recovery_in_progress_at_request.append(
                bool(getattr(self._controller, "_recovering", True))
            )
        return self.text


class HaikuSummaryTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        root = Path(self.directory.name)
        self.state_path = root / "state.json"
        self.events_path = root / "events.json"
        self.retry_path = root / "retry.json"
        self.key_path = root / "anthropic_key"
        self.key_path.write_text("test-key\n")
        self.event = {
            "id": "evt-1",
            "timestamp": "2026-09-02T22:00:00Z",
            "revision": "2" * 40,
            "type": "safety-stop",
            "severity": "warning",
            "reason": "memory",
            "metrics": {"mem_available": 1},
            "action": "stop",
            "summary": "",
        }
        self._original_worktree = monitor.CANDIDATE_WORKTREE
        monitor.CANDIDATE_WORKTREE = str(
            write_detached_worktree(root, "2" * 40)
        )


    def tearDown(self):
        self.directory.cleanup()
        monitor.CANDIDATE_WORKTREE = self._original_worktree


    def test_redaction_removes_credentials(self):
        text = "Authorization: Bearer abc123\nx-api-key: secret\n?access_token=query-secret"
        redacted = monitor.redact(text, ["secret"])
        self.assertNotIn("abc123", redacted)
        self.assertNotIn("secret", redacted)
        self.assertIn("[REDACTED]", redacted)

    def test_evidence_is_bounded(self):
        evidence = monitor.build_evidence(self.event, "line\n" * 10000, [])
        self.assertLessEqual(len(evidence.encode()), 32 * 1024)
        self.assertLessEqual(evidence.count("\n"), 200)

    def test_anthropic_request_has_no_tools(self):
        transport = FakeTransport({"content": [{"type": "text", "text": "summary"}]})
        client = monitor.AnthropicClient(self.key_path, transport)
        self.assertEqual(client.summarize("evidence"), "summary")
        request = transport.requests[0]
        self.assertEqual(request.url, "https://api.anthropic.com/v1/messages")
        self.assertEqual(request.timeout, 30)
        self.assertEqual(request.body["model"], "claude-haiku-4-5")
        self.assertEqual(request.body["max_tokens"], 512)
        self.assertNotIn("tools", request.body)

    def test_model_text_never_changes_actions(self):
        runner = FakeRunner()
        client = FakeModel("systemctl start arbitrary.service")
        controller = monitor.Controller(
            runner,
            self.state_path,
            self.events_path,
            self.retry_path,
            model=client,
        )
        monitor.append_event(self.events_path, self.event)
        controller.summarize(self.event)
        self.assertEqual(runner.calls, [])
        self.assertEqual(
            json.loads(self.events_path.read_text())[0]["summary"],
            "systemctl start arbitrary.service",
        )

    def test_recovery_completes_before_model_request(self):
        runner = FakeRunner(
            active={"vasher-prebuild-candidate.service": True},
        )
        client = FakeModel("summary")
        client._runner = runner
        controller = monitor.Controller(
            runner,
            self.state_path,
            self.events_path,
            self.retry_path,
            model=client,
        )
        controller.recover(sample(90, nix_memory=256 * monitor.MIB), monitor.Decision("stop", "memory"))
        self.assertEqual(
            client.runner_calls_at_request,
            [
                ("systemctl", "stop", "vasher-prebuild-candidate.service"),
                ("systemctl", "start", "vasher-prebuild-cleanup.service"),
                ("systemctl", "start", "--no-block", "vasher-prebuild-retry.service"),
            ],
        )
        self.assertEqual(runner.calls, client.runner_calls_at_request)
        events = json.loads(self.events_path.read_text())
        safety = next(event for event in events if event["type"] == "safety-stop")
        self.assertEqual(safety["summary"], "summary")

    def test_no_model_request_while_recovery_in_progress(self):
        runner = FakeRunner(
            active={"vasher-prebuild-candidate.service": True},
            cleanup_result=1,
        )
        client = FakeModel("summary")
        controller = monitor.Controller(
            runner,
            self.state_path,
            self.events_path,
            self.retry_path,
            model=client,
        )
        client._controller = controller
        controller.recover(
            sample(90, nix_memory=256 * monitor.MIB),
            monitor.Decision("stop", "memory"),
        )
        self.assertEqual(client.recovery_in_progress_at_request, [False, False])
        events = json.loads(self.events_path.read_text())
        attention = next(event for event in events if event["type"] == "needs-attention")
        safety = next(event for event in events if event["type"] == "safety-stop")
        self.assertEqual(attention["summary"], "summary")
        self.assertEqual(safety["summary"], "summary")

    def test_recovery_leafs_summarized_after_transition_completes(self):
        runner = FakeRunner(
            active={"vasher-prebuild-candidate.service": True},
            cleanup_result=1,
        )
        client = FakeModel("summary")
        client._runner = runner
        controller = monitor.Controller(
            runner,
            self.state_path,
            self.events_path,
            self.retry_path,
            model=client,
        )
        controller.recover(
            sample(90, nix_memory=256 * monitor.MIB),
            monitor.Decision("stop", "memory"),
        )
        self.assertEqual(
            client.runner_calls_at_request,
            [
                ("systemctl", "stop", "vasher-prebuild-candidate.service"),
                ("systemctl", "start", "vasher-prebuild-cleanup.service"),
            ],
        )
        events = json.loads(self.events_path.read_text())
        attention = next(event for event in events if event["type"] == "needs-attention")
        safety = next(event for event in events if event["type"] == "safety-stop")
        self.assertEqual(attention["summary"], "summary")
        self.assertEqual(safety["summary"], "summary")

    def test_observe_resume_summarizes_existing_safety_stop(self):
        runner = FakeRunner()
        client = FakeModel("summary")
        state = monitor.MonitorState.for_revision("1" * 40, "2" * 40)
        state.phase = "stopping"
        state.boot_id = "same-boot"
        monitor.atomic_json(self.state_path, dataclasses.asdict(state))
        monitor.append_event(self.events_path, dict(self.event))
        controller = monitor.Controller(
            runner,
            self.state_path,
            self.events_path,
            self.retry_path,
            boot_id="same-boot",
            model=client,
        )
        idle = sample(90, active_unit=None, nix_memory=256 * monitor.MIB)
        controller.observe(idle)
        self.assertEqual(client.requests, 1)
        events = json.loads(self.events_path.read_text())
        safety = next(event for event in events if event["type"] == "safety-stop")
        self.assertEqual(safety["summary"], "summary")

    def test_observe_resume_cleaning_summarizes_existing_safety_stop(self):
        runner = FakeRunner()
        client = FakeModel("summary")
        state = monitor.MonitorState.for_revision("1" * 40, "2" * 40)
        state.phase = "cleaning"
        state.boot_id = "same-boot"
        state.cleaning_since = 0.0
        monitor.atomic_json(self.state_path, dataclasses.asdict(state))
        monitor.append_event(self.events_path, dict(self.event))
        controller = monitor.Controller(
            runner,
            self.state_path,
            self.events_path,
            self.retry_path,
            boot_id="same-boot",
            model=client,
        )
        idle = sample(90, active_unit=None, nix_memory=256 * monitor.MIB)
        controller.observe(idle)
        self.assertEqual(client.requests, 1)
        events = json.loads(self.events_path.read_text())
        safety = next(event for event in events if event["type"] == "safety-stop")
        self.assertEqual(safety["summary"], "summary")

    def test_observe_resume_retrying_summarizes_existing_safety_stop(self):
        runner = FakeRunner()
        client = FakeModel("summary")
        state = monitor.MonitorState.for_revision("1" * 40, "2" * 40)
        state.phase = "retrying"
        state.retry_count = 1
        state.boot_id = "same-boot"
        monitor.atomic_json(self.state_path, dataclasses.asdict(state))
        monitor.append_event(self.events_path, dict(self.event))
        controller = monitor.Controller(
            runner,
            self.state_path,
            self.events_path,
            self.retry_path,
            boot_id="same-boot",
            model=client,
        )
        idle = sample(90, active_unit=None, nix_memory=256 * monitor.MIB)
        controller.observe(idle)
        self.assertEqual(client.requests, 1)
        events = json.loads(self.events_path.read_text())
        safety = next(event for event in events if event["type"] == "safety-stop")
        self.assertEqual(safety["summary"], "summary")

    def test_resume_never_resummarizes_completed_events(self):
        runner = FakeRunner()
        client = FakeModel("summary")
        state = monitor.MonitorState.for_revision("1" * 40, "2" * 40)
        state.phase = "retrying"
        state.retry_count = 1
        state.boot_id = "same-boot"
        monitor.atomic_json(self.state_path, dataclasses.asdict(state))
        summarized = dict(self.event)
        summarized["id"] = "evt-summarized"
        summarized["summary"] = "already explained"
        failed = dict(self.event)
        failed["id"] = "evt-inference-error"
        failed["inferenceError"] = "timeout"
        monitor.append_event(self.events_path, summarized)
        monitor.append_event(self.events_path, failed)
        controller = monitor.Controller(
            runner,
            self.state_path,
            self.events_path,
            self.retry_path,
            boot_id="same-boot",
            model=client,
        )
        idle = sample(90, active_unit=None, nix_memory=256 * monitor.MIB)
        controller.observe(idle)
        self.assertEqual(client.requests, 0)
        events = json.loads(self.events_path.read_text())
        for event in events:
            if event.get("type") in monitor.SUMMARY_EVENTS:
                self.assertTrue(event.get("summary") or event.get("inferenceError"))

if __name__ == "__main__":
    unittest.main()
