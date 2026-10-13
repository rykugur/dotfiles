#!/usr/bin/env python3
from __future__ import annotations

import importlib.util
import io
import json
import shutil
import sys
import tempfile
import threading
import time
import unittest
from datetime import datetime, timedelta, timezone
from pathlib import Path

MODULE_PATH = Path(__file__).parents[2] / "modules/nixos/vasher-agent-verb.py"
SPEC = importlib.util.spec_from_file_location("vasher_agent_verb", MODULE_PATH)
assert SPEC is not None
assert SPEC.loader is not None
channel = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = channel
SPEC.loader.exec_module(channel)

BASE = "a" * 40
REVISION = "b" * 40
OTHER = "c" * 40
NOW = datetime(2026, 10, 12, 15, 30, 0, tzinfo=timezone.utc).timestamp()
TODAY = datetime.fromtimestamp(NOW, timezone.utc).date()
KNOWN = (
    "nixpkgs",
    "home-manager",
    "sops-nix",
    "flake-parts",
    "import-tree",
    "stylix",
    "hyprland",
    "catppuccin",
    "nixos-hardware",
    "omp",
)


def hold_request(**changes: object) -> dict:
    request = {
        "verb": "hold-input",
        "input": "nixpkgs",
        "revision": REVISION,
        "expires": (TODAY + timedelta(days=29)).isoformat(),
        "reason": "upstream kernel regression",
    }
    request.update(changes)
    return request


class ChannelCase(unittest.TestCase):
    def setUp(self) -> None:
        self.root = Path(tempfile.mkdtemp(prefix="vasher-agent-"))
        self.addCleanup(shutil.rmtree, self.root, True)
        self.agent_dir = self.root / "agent"
        self.dashboard = self.root / "dashboard"
        self.monitor = self.root / "monitor"
        for directory in (self.agent_dir, self.dashboard, self.monitor):
            directory.mkdir(parents=True)
        self.status_path = self.dashboard / "status.json"
        self.fault_path = self.monitor / "storage-fault.json"
        self.prebuild_lock_path = self.root / "prebuild.lock"
        self.events_path = self.agent_dir / "events.json"
        self.retry_path = self.agent_dir / "retry.json"
        self.verbs_path = self.agent_dir / "verbs.json"
        self.worktree = self.root / "worktrees/candidate"
        self.started: list[tuple[str, object]] = []
        self.logged: list[tuple[str, str]] = []
        self.busy = False
        self.inputs: frozenset[str] | None = frozenset(KNOWN)
        self.metadata_calls = 0
        self.now = NOW
        self.write_status()

    # --- helpers ---------------------------------------------------------

    def write_status(self, **changes: object) -> None:
        status = {
            "state": "needs-attention",
            "mode": "candidate",
            "baseRevision": BASE,
            "revision": REVISION,
            "output": None,
            "exitCode": 1,
        }
        status.update(changes)
        self.status_path.write_text(json.dumps(status))

    def start_unit(self, unit: str) -> None:
        narrow = self.agent_dir / "narrow-request.json"
        seen: object = None
        if narrow.exists():
            seen = ("narrow", json.loads(narrow.read_text()))
        elif self.retry_path.exists():
            seen = ("retry", json.loads(self.retry_path.read_text()))
        self.started.append((unit, seen))

    def flake_inputs(self, worktree: Path) -> frozenset[str] | None:
        self.metadata_calls += 1
        return self.inputs

    def ctx(self, **changes: object):
        values = {
            "now": self.now,
            "agent_dir": self.agent_dir,
            "status_path": self.status_path,
            "fault_path": self.fault_path,
            "prebuild_lock_path": self.prebuild_lock_path,
            "worktree": self.worktree,
            "lock_busy": lambda path: self.busy,
            "flake_inputs": self.flake_inputs,
            "start_unit": self.start_unit,
            "log": lambda verb, reason: self.logged.append((verb, reason)),
        }
        values.update(changes)
        return channel.Context(**values)

    def call(self, request: dict):
        return channel.handle(request, self.ctx())

    def events(self) -> list[dict]:
        if not self.events_path.exists():
            return []
        return json.loads(self.events_path.read_text())

    def holds(self) -> dict:
        path = self.agent_dir / "holds.json"
        if not path.exists():
            return {}
        return json.loads(path.read_text())

    def ledger(self) -> dict:
        return json.loads(self.verbs_path.read_text())

    def assertAccepted(self, response) -> None:
        self.assertTrue(response.accepted, msg=response.reason)
        self.assertEqual(response.code, 0)
        self.assertIsNotNone(response.event_id)

    def assertRejected(self, response, reason: str) -> None:
        self.assertFalse(response.accepted)
        self.assertEqual(response.reason, reason)
        self.assertEqual(response.code, 1)


class AcceptedVerbTests(ChannelCase):
    def test_retry_exact_writes_the_request_then_starts_the_unit(self):
        response = self.call({"verb": "retry-exact", "revision": REVISION})
        self.assertAccepted(response)
        self.assertEqual(
            json.loads(self.retry_path.read_text()),
            {"baseRevision": BASE, "revision": REVISION},
        )
        self.assertEqual(
            self.started,
            [
                (
                    "vasher-prebuild-retry.service",
                    ("retry", {"baseRevision": BASE, "revision": REVISION}),
                )
            ],
        )

    def test_retry_exact_accepts_the_failed_state(self):
        self.write_status(state="failed")
        self.assertAccepted(self.call({"verb": "retry-exact", "revision": REVISION}))

    def test_narrow_inputs_writes_the_request_before_the_unit_start(self):
        response = self.call(
            {"verb": "narrow-inputs", "base": BASE, "inputs": ["nixpkgs", "stylix"]}
        )
        self.assertAccepted(response)
        self.assertEqual(
            self.started,
            [
                (
                    "vasher-prebuild-narrow.service",
                    ("narrow", {"base": BASE, "inputs": ["nixpkgs", "stylix"]}),
                )
            ],
        )

    def test_narrow_inputs_accepts_eight_known_inputs(self):
        response = self.call(
            {"verb": "narrow-inputs", "base": BASE, "inputs": list(KNOWN[:8])}
        )
        self.assertAccepted(response)

    def test_hold_input_records_the_hold(self):
        response = self.call(hold_request())
        self.assertAccepted(response)
        holds = self.holds()
        self.assertEqual(set(holds), {"nixpkgs"})
        record = holds["nixpkgs"]
        self.assertEqual(record["revision"], REVISION)
        self.assertEqual(record["expires"], (TODAY + timedelta(days=29)).isoformat())
        self.assertEqual(record["reason"], "upstream kernel regression")
        self.assertTrue(record["createdAt"].startswith("2026-10-12T"))
        self.assertEqual(self.started, [])

    def test_hold_input_keeps_the_other_holds(self):
        self.assertAccepted(self.call(hold_request()))
        self.assertAccepted(self.call(hold_request(input="stylix")))
        self.assertEqual(set(self.holds()), {"nixpkgs", "stylix"})

    def test_release_input_removes_a_held_input(self):
        self.assertAccepted(self.call(hold_request()))
        self.assertAccepted(self.call(hold_request(input="stylix")))
        response = self.call({"verb": "release-input", "input": "nixpkgs"})
        self.assertAccepted(response)
        self.assertEqual(set(self.holds()), {"stylix"})

    def test_an_accepted_verb_is_not_logged_as_a_denial(self):
        self.assertAccepted(self.call(hold_request()))
        self.assertEqual(self.logged, [])


class StorageFaultTests(ChannelCase):
    def requests(self) -> list[dict]:
        return [
            {"verb": "retry-exact", "revision": REVISION},
            {"verb": "narrow-inputs", "base": BASE, "inputs": ["nixpkgs"]},
            hold_request(),
            {"verb": "release-input", "input": "nixpkgs"},
        ]

    def test_every_verb_is_rejected_while_the_fault_file_exists(self):
        self.fault_path.write_text(json.dumps({"pattern": "csum failed"}))
        for request in self.requests():
            with self.subTest(verb=request["verb"]):
                self.assertRejected(self.call(request), "storage-fault")
        self.assertEqual(self.started, [])
        self.assertEqual(self.holds(), {})
        self.assertTrue(self.fault_path.exists())
        self.assertEqual(len(self.events()), 4)


class LockTests(ChannelCase):
    def test_build_verbs_are_rejected_while_the_prebuild_lock_is_held(self):
        self.busy = True
        self.assertRejected(
            self.call({"verb": "retry-exact", "revision": REVISION}), "busy"
        )
        self.assertRejected(
            self.call({"verb": "narrow-inputs", "base": BASE, "inputs": ["nixpkgs"]}),
            "busy",
        )
        self.assertEqual(self.started, [])

    def test_hold_verbs_survive_a_running_build(self):
        self.busy = True
        self.assertAccepted(self.call(hold_request()))
        self.assertAccepted(self.call({"verb": "release-input", "input": "nixpkgs"}))

    def test_a_held_channel_lock_rejects_the_request(self):
        descriptor = channel.acquire_channel_lock(
            self.agent_dir / "channel.lock", 1.0
        )
        self.assertIsNotNone(descriptor)
        try:
            response = channel.handle(hold_request(), self.ctx(lock_timeout=0.05))
        finally:
            import os

            os.close(descriptor)
        self.assertRejected(response, "busy")
        self.assertEqual(self.holds(), {})

    def test_the_channel_lock_is_not_the_prebuild_lock(self):
        default = channel.Context(now=NOW)
        self.assertNotEqual(default.channel_lock_path, default.prebuild_lock_path)
        self.assertEqual(
            str(default.channel_lock_path), "/var/lib/vasher/agent/channel.lock"
        )


class ConcurrencyTests(ChannelCase):
    def run_together(self, first: dict, second: dict) -> list:
        results: dict[int, object] = {}
        start = threading.Barrier(2)

        def run(index: int, request: dict) -> None:
            start.wait()
            results[index] = channel.handle(request, self.ctx())

        threads = [
            threading.Thread(target=run, args=(0, first)),
            threading.Thread(target=run, args=(1, second)),
        ]
        for thread in threads:
            thread.start()
        for thread in threads:
            thread.join(30)
            self.assertFalse(thread.is_alive())
        return [results[0], results[1]]

    def test_two_requests_cannot_share_the_last_budget_slot(self):
        # Seven accepted verbs leave exactly one slot.
        self.verbs_path.write_text(
            json.dumps(
                {
                    "accepted": [
                        {"id": str(index), "at": NOW, "verb": "hold-input",
                         "revision": REVISION}
                        for index in range(7)
                    ],
                    "rejected": [],
                    "retries": {},
                }
            )
        )
        # The expensive check sits inside the critical section, so an
        # unserialised pair would both read seven and both accept.
        slow = self.flake_inputs

        def delayed(worktree: Path):
            time.sleep(0.2)
            return slow(worktree)

        self.flake_inputs = delayed
        responses = self.run_together(
            hold_request(input="nixpkgs"), hold_request(input="stylix")
        )
        reasons = sorted(
            "accepted" if response.accepted else response.reason
            for response in responses
        )
        self.assertEqual(reasons, ["accepted", "budget"])
        self.assertEqual(len(self.ledger()["accepted"]), 8)

    def test_two_requests_cannot_both_retry_one_revision(self):
        starter = self.start_unit

        def delayed(unit: str) -> None:
            time.sleep(0.2)
            starter(unit)

        self.start_unit = delayed
        request = {"verb": "retry-exact", "revision": REVISION}
        responses = self.run_together(dict(request), dict(request))
        reasons = sorted(
            "accepted" if response.accepted else response.reason
            for response in responses
        )
        self.assertEqual(reasons, ["accepted", "retry-budget"])
        self.assertEqual(len(self.started), 1)
        self.assertEqual(self.ledger()["retries"], {REVISION: 1})


class RetryPreconditionTests(ChannelCase):
    def test_a_successful_state_rejects_the_retry(self):
        self.write_status(state="success")
        self.assertRejected(
            self.call({"verb": "retry-exact", "revision": REVISION}), "state"
        )

    def test_an_unknown_revision_is_rejected(self):
        self.assertRejected(
            self.call({"verb": "retry-exact", "revision": OTHER}), "revision"
        )

    def test_a_malformed_revision_is_rejected(self):
        self.assertRejected(
            self.call({"verb": "retry-exact", "revision": "HEAD"}), "revision"
        )

    def test_a_second_retry_of_the_same_revision_is_rejected(self):
        self.assertAccepted(self.call({"verb": "retry-exact", "revision": REVISION}))
        self.assertRejected(
            self.call({"verb": "retry-exact", "revision": REVISION}), "retry-budget"
        )
        self.assertEqual(len(self.started), 1)

    def test_a_missing_status_record_is_rejected(self):
        self.status_path.unlink()
        self.assertRejected(
            self.call({"verb": "retry-exact", "revision": REVISION}), "state"
        )

    def test_a_failed_unit_start_rejects_and_keeps_the_spent_retry(self):
        def explode(unit: str) -> None:
            raise OSError("systemctl is unavailable")

        self.start_unit = explode
        response = channel.handle(
            {"verb": "retry-exact", "revision": REVISION}, self.ctx()
        )
        self.assertRejected(response, "unit")
        ledger = self.ledger()
        self.assertEqual(ledger["retries"], {REVISION: 1})
        self.assertEqual(len(ledger["accepted"]), 1)
        self.assertEqual(len(ledger["rejected"]), 1)


class NarrowPreconditionTests(ChannelCase):
    def narrow(self, **changes: object) -> dict:
        request = {"verb": "narrow-inputs", "base": BASE, "inputs": ["nixpkgs"]}
        request.update(changes)
        return request

    def test_a_stale_base_is_rejected(self):
        self.assertRejected(self.call(self.narrow(base=OTHER)), "base")

    def test_an_empty_input_list_is_rejected(self):
        self.assertRejected(self.call(self.narrow(inputs=[])), "inputs")

    def test_nine_inputs_are_rejected(self):
        self.assertRejected(self.call(self.narrow(inputs=list(KNOWN[:9]))), "inputs")

    def test_an_unknown_input_name_is_rejected(self):
        self.assertRejected(self.call(self.narrow(inputs=["nixpkgs", "evil"])), "inputs")

    def test_a_repeated_input_name_is_rejected(self):
        self.assertRejected(
            self.call(self.narrow(inputs=["nixpkgs", "nixpkgs"])), "inputs"
        )

    def test_an_input_name_with_a_path_is_rejected(self):
        self.assertRejected(
            self.call(self.narrow(inputs=["../../etc/passwd"])), "inputs"
        )

    def test_a_missing_worktree_rejects_the_request(self):
        self.inputs = None
        self.assertRejected(self.call(self.narrow()), "inputs")
        self.assertEqual(self.started, [])


class HoldPreconditionTests(ChannelCase):
    def test_an_expiry_beyond_thirty_days_is_rejected(self):
        expires = (TODAY + timedelta(days=31)).isoformat()
        self.assertRejected(self.call(hold_request(expires=expires)), "hold")

    def test_an_expired_date_is_rejected(self):
        expires = (TODAY - timedelta(days=1)).isoformat()
        self.assertRejected(self.call(hold_request(expires=expires)), "hold")

    def test_a_malformed_date_is_rejected(self):
        self.assertRejected(self.call(hold_request(expires="soon")), "hold")

    def test_a_non_hex_revision_is_rejected(self):
        self.assertRejected(self.call(hold_request(revision="deadbeef")), "hold")

    def test_a_missing_reason_is_rejected(self):
        request = hold_request()
        del request["reason"]
        self.assertRejected(self.call(request), "hold")

    def test_an_empty_reason_is_rejected(self):
        self.assertRejected(self.call(hold_request(reason="   ")), "hold")

    def test_a_control_character_in_the_reason_is_rejected(self):
        self.assertRejected(self.call(hold_request(reason="a\nb")), "hold")

    def test_an_unknown_input_name_is_rejected(self):
        self.assertRejected(self.call(hold_request(input="evil")), "inputs")

    def test_releasing_an_input_that_is_not_held_is_rejected(self):
        self.assertRejected(
            self.call({"verb": "release-input", "input": "nixpkgs"}), "hold"
        )


class CheckOrderTests(ChannelCase):
    def test_a_cheap_rejection_never_reads_the_flake_metadata(self):
        self.assertRejected(self.call(hold_request(expires="soon")), "hold")
        self.assertRejected(
            self.call({"verb": "narrow-inputs", "base": OTHER, "inputs": ["nixpkgs"]}),
            "base",
        )
        self.assertRejected(
            self.call({"verb": "retry-exact", "revision": "HEAD"}), "revision"
        )
        self.fault_path.write_text("{}")
        self.assertRejected(self.call(hold_request()), "storage-fault")
        self.fault_path.unlink()
        self.busy = True
        self.assertRejected(
            self.call({"verb": "narrow-inputs", "base": BASE, "inputs": ["nixpkgs"]}),
            "busy",
        )
        self.assertEqual(self.metadata_calls, 0)

    def test_an_exhausted_budget_never_reads_the_flake_metadata(self):
        self.verbs_path.write_text(
            json.dumps(
                {
                    "accepted": [
                        {"id": str(index), "at": NOW, "verb": "hold-input",
                         "revision": REVISION}
                        for index in range(8)
                    ],
                    "rejected": [],
                    "retries": {},
                }
            )
        )
        self.assertRejected(self.call(hold_request()), "budget")
        self.assertEqual(self.metadata_calls, 0)

    def test_an_accepted_verb_reads_the_flake_metadata_once(self):
        self.assertAccepted(self.call(hold_request()))
        self.assertEqual(self.metadata_calls, 1)


class BudgetTests(ChannelCase):
    def accept_eight(self) -> None:
        for index in range(8):
            response = self.call(hold_request(input=KNOWN[index]))
            self.assertAccepted(response)

    def test_the_ninth_verb_in_a_day_is_rejected(self):
        self.accept_eight()
        self.assertRejected(self.call(hold_request(input=KNOWN[8])), "budget")

    def test_the_budget_survives_a_reload_from_disk(self):
        self.accept_eight()
        self.assertEqual(len(self.ledger()["accepted"]), 8)
        # A fresh context reads the same file, so a restart changes nothing.
        self.assertRejected(self.call(hold_request(input=KNOWN[8])), "budget")

    def test_the_window_rolls_forward(self):
        self.accept_eight()
        self.now = NOW + 24 * 60 * 60 + 1
        self.assertAccepted(self.call(hold_request(input=KNOWN[8])))
        self.assertEqual(len(self.ledger()["accepted"]), 1)

    def test_rejected_verbs_do_not_spend_the_accepted_budget(self):
        for _ in range(9):
            self.assertRejected(self.call(hold_request(expires="soon")), "hold")
        self.assertAccepted(self.call(hold_request()))

    def test_the_thirty_third_rejection_in_a_day_is_metered(self):
        for _ in range(32):
            self.assertRejected(self.call(hold_request(expires="soon")), "hold")
        self.assertRejected(self.call(hold_request(expires="soon")), "budget")
        # A valid verb is refused too, and costs no work.
        self.assertRejected(self.call(hold_request()), "budget")
        self.assertEqual(self.metadata_calls, 0)
        self.assertEqual(self.holds(), {})

    def test_the_rejection_window_rolls_forward(self):
        for _ in range(32):
            self.assertRejected(self.call(hold_request(expires="soon")), "hold")
        self.now = NOW + 24 * 60 * 60 + 1
        self.assertAccepted(self.call(hold_request()))

    def test_rejection_lockout_does_not_extend_itself(self):
        for _ in range(32):
            self.assertRejected(self.call(hold_request(expires="soon")), "hold")
        # These probes answer budget but do not create newer rejection entries.
        for _ in range(4):
            self.assertRejected(self.call(hold_request(expires="soon")), "budget")
        self.assertEqual(len(self.ledger()["rejected"]), 32)
        self.now = NOW + 24 * 60 * 60 + 1
        self.assertAccepted(self.call(hold_request()))

    def test_a_corrupt_ledger_counts_as_an_exhausted_budget(self):
        self.verbs_path.write_text("{not json")
        self.assertRejected(self.call(hold_request()), "budget")
        # The damaged file is left for an operator, not silently replaced.
        self.assertEqual(self.verbs_path.read_text(), "{not json")

    def test_a_ledger_of_the_wrong_shape_counts_as_exhausted(self):
        self.verbs_path.write_text("[]")
        self.assertRejected(self.call(hold_request()), "budget")


class LedgerTests(ChannelCase):
    def test_an_accepted_verb_appends_one_agent_event(self):
        self.assertAccepted(self.call(hold_request()))
        events = self.events()
        self.assertEqual(len(events), 1)
        event = events[0]
        self.assertEqual(event["source"], "agent")
        self.assertEqual(event["verb"], "hold-input")
        self.assertTrue(event["accepted"])
        self.assertEqual(event["revision"], REVISION)

    def test_a_rejected_verb_appends_one_agent_event(self):
        self.assertRejected(self.call(hold_request(expires="soon")), "hold")
        events = self.events()
        self.assertEqual(len(events), 1)
        self.assertEqual(events[0]["source"], "agent")
        self.assertEqual(events[0]["verb"], "hold-input")
        self.assertFalse(events[0]["accepted"])
        self.assertEqual(events[0]["reason"], "hold")

    def test_the_newest_event_comes_first_and_matches_the_response(self):
        first = self.call(hold_request())
        second = self.call({"verb": "release-input", "input": "nixpkgs"})
        events = self.events()
        self.assertEqual(
            [event["id"] for event in events], [second.event_id, first.event_id]
        )

    def test_the_ledger_keeps_one_hundred_events(self):
        self.events_path.write_text(
            json.dumps([{"id": str(index)} for index in range(100)])
        )
        self.assertRejected(self.call(hold_request(expires="soon")), "hold")
        self.assertEqual(len(self.events()), 100)

    def test_the_event_file_is_the_agent_file_not_the_dashboard_file(self):
        self.assertAccepted(self.call(hold_request()))
        self.assertTrue(self.events_path.exists())
        self.assertEqual(sorted(path.name for path in self.dashboard.iterdir()),
                         ["status.json"])
        self.assertEqual(sorted(path.name for path in self.monitor.iterdir()), [])


class DenialLogTests(ChannelCase):
    def test_a_rejection_logs_the_verb_and_the_reason(self):
        self.assertRejected(self.call(hold_request(expires="soon")), "hold")
        self.assertEqual(self.logged, [("hold-input", "hold")])

    def test_a_malformed_request_logs_without_the_body(self):
        channel.process(b'{"verb": "rm -rf /", "secret": "hunter2"}', self.ctx())
        channel.process(b"not json", self.ctx())
        self.assertEqual(
            self.logged, [("unknown", "verb"), ("unknown", "malformed")]
        )
        for verb, reason in self.logged:
            self.assertNotIn("hunter2", verb + reason)
            self.assertNotIn("rm -rf", verb + reason)

    def test_the_default_logger_is_syslog_and_never_takes_a_body(self):
        self.assertIs(channel.Context(now=NOW).log, channel.log_denied)
        self.assertEqual(
            channel.log_denied.__code__.co_varnames[
                : channel.log_denied.__code__.co_argcount
            ],
            ("verb", "reason"),
        )


class WritablePathTests(ChannelCase):
    def test_every_written_path_lives_in_the_agent_directory(self):
        default = channel.Context(now=NOW)
        for path in (
            default.holds_path,
            default.narrow_request_path,
            default.verbs_path,
            default.retry_path,
            default.events_path,
            default.channel_lock_path,
        ):
            with self.subTest(path=str(path)):
                self.assertEqual(path.parent, channel.AGENT_DIR)
        self.assertEqual(str(channel.AGENT_DIR), "/var/lib/vasher/agent")

    def test_the_read_only_inputs_live_outside_the_agent_directory(self):
        default = channel.Context(now=NOW)
        self.assertEqual(
            str(default.status_path), "/var/lib/vasher/dashboard/status.json"
        )
        self.assertEqual(
            str(default.fault_path), "/var/lib/vasher/monitor/storage-fault.json"
        )
        self.assertEqual(
            str(default.prebuild_lock_path), "/var/lib/vasher/prebuild.lock"
        )

    def test_a_full_round_of_verbs_writes_nothing_outside_the_agent_directory(self):
        self.fault_path.write_text("{}")
        before = sorted(path.name for path in self.monitor.iterdir())
        self.assertRejected(self.call(hold_request()), "storage-fault")
        self.assertEqual(sorted(path.name for path in self.monitor.iterdir()), before)
        self.fault_path.unlink()
        self.assertAccepted(self.call({"verb": "retry-exact", "revision": REVISION}))
        self.assertAccepted(self.call(hold_request()))
        self.assertEqual(sorted(path.name for path in self.monitor.iterdir()), [])
        self.assertEqual(
            sorted(path.name for path in self.dashboard.iterdir()), ["status.json"]
        )

    def test_the_temporary_file_name_is_unique_per_write(self):
        decoy = self.agent_dir / ".holds.json.tmp"
        decoy.write_text("owned by another writer")
        self.assertAccepted(self.call(hold_request()))
        self.assertEqual(decoy.read_text(), "owned by another writer")
        leftovers = [
            path.name
            for path in self.agent_dir.iterdir()
            if path.name.startswith(".holds.json.") and path != decoy
        ]
        self.assertEqual(leftovers, [])

    def test_atomic_json_applies_the_requested_mode(self):
        target = self.agent_dir / "mode.json"
        channel.atomic_json(target, {"a": 1}, 0o644)
        self.assertEqual(target.stat().st_mode & 0o777, 0o644)
        channel.atomic_json(target, {"a": 2}, 0o600)
        self.assertEqual(target.stat().st_mode & 0o777, 0o600)


class MalformedRequestTests(ChannelCase):
    def process(self, data: bytes) -> tuple[dict, int]:
        return channel.process(data, self.ctx())

    def test_an_unknown_verb_is_malformed(self):
        payload, code = self.process(json.dumps({"verb": "rm-rf"}).encode())
        self.assertEqual(code, 2)
        self.assertFalse(payload["accepted"])
        self.assertIsNone(payload["eventId"])
        self.assertEqual(self.events(), [])

    def test_a_missing_verb_is_malformed(self):
        _, code = self.process(b'{"revision": "x"}')
        self.assertEqual(code, 2)

    def test_a_non_object_body_is_malformed(self):
        for body in (b"[]", b'"retry-exact"', b"null", b"", b"{"):
            with self.subTest(body=body):
                _, code = self.process(body)
                self.assertEqual(code, 2)

    def test_an_oversized_body_is_malformed(self):
        reason = "x" * 4096
        _, code = self.process(json.dumps(hold_request(reason=reason)).encode())
        self.assertEqual(code, 2)

    def test_a_body_at_the_limit_is_parsed(self):
        request = hold_request()
        padding = 4096 - len(json.dumps(request).encode()) - len(', "note": ""')
        request["note"] = "x" * padding
        body = json.dumps(request).encode()
        self.assertLessEqual(len(body), 4096)
        payload, code = self.process(body)
        self.assertEqual(code, 0, msg=payload)


class MainTests(ChannelCase):
    def run_main(self, body: bytes) -> tuple[dict, int]:
        stdin = io.TextIOWrapper(io.BytesIO(body))
        out = io.StringIO()
        original_in, original_out = sys.stdin, sys.stdout
        sys.stdin, sys.stdout = stdin, out
        try:
            code = channel.main(self.ctx())
        finally:
            sys.stdin, sys.stdout = original_in, original_out
        printed = out.getvalue()
        self.assertTrue(printed.endswith("\n"))
        self.assertEqual(len(printed.splitlines()), 1)
        return json.loads(printed), code

    def test_main_accepts_and_exits_zero(self):
        payload, code = self.run_main(json.dumps(hold_request()).encode())
        self.assertEqual(code, 0)
        self.assertTrue(payload["accepted"])
        self.assertEqual(payload["reason"], "accepted")
        self.assertEqual(payload["eventId"], self.events()[0]["id"])

    def test_main_rejects_and_exits_one(self):
        payload, code = self.run_main(
            json.dumps(hold_request(expires="soon")).encode()
        )
        self.assertEqual(code, 1)
        self.assertFalse(payload["accepted"])
        self.assertEqual(payload["reason"], "hold")

    def test_main_reports_malformed_and_exits_two(self):
        payload, code = self.run_main(b"[]")
        self.assertEqual(code, 2)
        self.assertEqual(payload["reason"], "malformed")
        self.assertIsNone(payload["eventId"])

    def test_main_stops_reading_after_one_byte_past_the_limit(self):
        body = b"{" + b"x" * 8192
        payload, code = self.run_main(body)
        self.assertEqual(code, 2)
        self.assertEqual(payload["reason"], "malformed")

    def test_the_read_deadline_interrupts_a_silent_client(self):
        class Blocking:
            def read(self, size: int) -> bytes:
                time.sleep(30)
                return b""

        stdin = type("Stream", (), {"buffer": Blocking()})()
        original_in = sys.stdin
        sys.stdin = stdin
        started = time.monotonic()
        try:
            with self.assertRaises(TimeoutError):
                channel.read_request(1)
        finally:
            sys.stdin = original_in
        self.assertLess(time.monotonic() - started, 5)

    def test_read_request_disarms_when_prior_handler_is_none(self):
        calls: list[tuple[str, object]] = []

        class Readable:
            def read(self, size: int) -> bytes:
                return b"{}"

        original_in = sys.stdin
        original_signal = channel.signal.signal
        original_alarm = channel.signal.alarm

        def fake_signal(signum: int, handler: object):
            calls.append(("signal", handler))
            return None

        def fake_alarm(seconds: int):
            calls.append(("alarm", seconds))
            return 0

        sys.stdin = type("Stream", (), {"buffer": Readable()})()
        channel.signal.signal = fake_signal
        channel.signal.alarm = fake_alarm
        try:
            self.assertEqual(channel.read_request(3), b"{}")
        finally:
            sys.stdin = original_in
            channel.signal.signal = original_signal
            channel.signal.alarm = original_alarm
        self.assertEqual(calls[0][0], "signal")
        self.assertTrue(callable(calls[0][1]))
        self.assertEqual(calls[1:], [("alarm", 3), ("alarm", 0)])

    def test_main_answers_a_read_timeout_with_exit_two(self):
        def expire(timeout: int = channel.STDIN_TIMEOUT) -> bytes:
            raise TimeoutError("timed out reading the request")

        original_read, channel.read_request = channel.read_request, expire
        out = io.StringIO()
        original_out, sys.stdout = sys.stdout, out
        try:
            code = channel.main(self.ctx())
        finally:
            channel.read_request = original_read
            sys.stdout = original_out
        self.assertEqual(code, 2)
        self.assertEqual(json.loads(out.getvalue())["reason"], "timeout")
        self.assertIn(("unknown", "timeout"), self.logged)

    def test_the_read_deadline_is_ten_seconds(self):
        self.assertEqual(channel.STDIN_TIMEOUT, 10)


class SystemContextTests(unittest.TestCase):
    def test_only_two_units_may_be_started(self):
        self.assertEqual(
            set(channel.ALLOWED_UNITS),
            {"vasher-prebuild-retry.service", "vasher-prebuild-narrow.service"},
        )
        with self.assertRaises(ValueError):
            channel.start_unit("sshd.service")

    def test_an_unlocked_file_reads_as_free(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "prebuild.lock"
            self.assertFalse(channel.probe_lock(path))
            path.write_text("")
            self.assertFalse(channel.probe_lock(path))

    def test_a_held_lock_reads_as_busy(self):
        import fcntl
        import os

        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "prebuild.lock"
            path.write_text("")
            holder = os.open(path, os.O_RDWR)
            fcntl.flock(holder, fcntl.LOCK_EX)
            try:
                self.assertTrue(channel.probe_lock(path))
            finally:
                os.close(holder)
            self.assertFalse(channel.probe_lock(path))


if __name__ == "__main__":
    unittest.main()
