#!/usr/bin/env python3
from __future__ import annotations

import importlib.util
import json
import shutil
import sys
import tempfile
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
        self.events_path = self.dashboard / "events.json"
        self.fault_path = self.monitor / "storage-fault.json"
        self.retry_path = self.monitor / "retry.json"
        self.lock_path = self.root / "prebuild.lock"
        self.worktree = self.root / "worktrees/candidate"
        self.started: list[tuple[str, object]] = []
        self.busy = False
        self.inputs: frozenset[str] | None = frozenset(KNOWN)
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
        retry = self.retry_path
        seen: object = None
        if narrow.exists():
            seen = ("narrow", json.loads(narrow.read_text()))
        elif retry.exists():
            seen = ("retry", json.loads(retry.read_text()))
        self.started.append((unit, seen))

    def ctx(self) -> object:
        return channel.Context(
            now=self.now,
            agent_dir=self.agent_dir,
            status_path=self.status_path,
            events_path=self.events_path,
            fault_path=self.fault_path,
            retry_path=self.retry_path,
            lock_path=self.lock_path,
            worktree=self.worktree,
            lock_busy=lambda path: self.busy,
            flake_inputs=lambda worktree: self.inputs,
            start_unit=self.start_unit,
        )

    def call(self, request: dict) -> object:
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

    def assertAccepted(self, response: object) -> None:
        self.assertTrue(response.accepted, msg=response.reason)
        self.assertEqual(response.code, 0)
        self.assertIsNotNone(response.event_id)

    def assertRejected(self, response: object, reason: str) -> None:
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
    def test_build_verbs_are_rejected_while_the_lock_is_held(self):
        self.busy = True
        self.assertRejected(
            self.call({"verb": "retry-exact", "revision": REVISION}), "busy"
        )
        self.assertRejected(
            self.call(
                {"verb": "narrow-inputs", "base": BASE, "inputs": ["nixpkgs"]}
            ),
            "busy",
        )
        self.assertEqual(self.started, [])

    def test_hold_verbs_survive_a_running_build(self):
        self.busy = True
        self.assertAccepted(self.call(hold_request()))
        self.assertAccepted(self.call({"verb": "release-input", "input": "nixpkgs"}))


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
        recorded = json.loads((self.agent_dir / "verbs.json").read_text())
        self.assertEqual(len(recorded["accepted"]), 8)
        # A fresh context reads the same file, so a restart changes nothing.
        self.assertRejected(self.call(hold_request(input=KNOWN[8])), "budget")

    def test_the_window_rolls_forward(self):
        self.accept_eight()
        self.now = NOW + 24 * 60 * 60 + 1
        self.assertAccepted(self.call(hold_request(input=KNOWN[8])))
        recorded = json.loads((self.agent_dir / "verbs.json").read_text())
        self.assertEqual(len(recorded["accepted"]), 1)

    def test_rejected_verbs_do_not_spend_the_budget(self):
        for _ in range(9):
            self.assertRejected(self.call(hold_request(expires="soon")), "hold")
        self.assertAccepted(self.call(hold_request()))


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
        self.assertEqual([event["id"] for event in events],
                         [second.event_id, first.event_id])

    def test_the_ledger_keeps_one_hundred_events(self):
        self.events_path.write_text(
            json.dumps([{"id": str(index)} for index in range(100)])
        )
        self.assertRejected(self.call(hold_request(expires="soon")), "hold")
        self.assertEqual(len(self.events()), 100)


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

    def test_the_default_paths_match_the_deployed_layout(self):
        self.assertEqual(
            str(channel.AGENT_DIR),
            "/var/lib/vasher/agent",
        )
        self.assertEqual(
            str(channel.FAULT_PATH),
            "/var/lib/vasher/monitor/storage-fault.json",
        )
        self.assertEqual(
            str(channel.RETRY_PATH),
            "/var/lib/vasher/monitor/retry.json",
        )

    def test_the_program_never_removes_a_file(self):
        source = MODULE_PATH.read_text()
        for forbidden in ("unlink(", "rmtree", "os.remove", "shutil"):
            self.assertNotIn(forbidden, source)


if __name__ == "__main__":
    unittest.main()
