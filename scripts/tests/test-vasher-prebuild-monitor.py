#!/usr/bin/env python3
from __future__ import annotations

import importlib.util
import stat
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


if __name__ == "__main__":
    unittest.main()
