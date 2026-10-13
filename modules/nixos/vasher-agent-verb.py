#!/usr/bin/env python3
"""Typed action channel for the Vasher supervisor.

The program reads one JSON object from standard input, re-validates every
field, and either performs one fixed action or rejects the request. It is the
only path by which a remote agent can act on Vasher, so the agent proposes and
this program decides.

Request text never becomes a command, a unit name, a path, a URL, or a
threshold: every command is a fixed argument list, every path is a constant,
and the only two units that may start are named here. The program ignores
SSH_ORIGINAL_COMMAND and never calls a shell.
"""
from __future__ import annotations

import fcntl
import json
import os
import re
import subprocess
import sys
import time
import uuid
from dataclasses import dataclass, field
from datetime import datetime, timedelta, timezone
from pathlib import Path
from typing import Callable

MAX_REQUEST_BYTES = 4096
MAX_INPUTS = 8
MAX_HOLD_DAYS = 30
MAX_REASON_CHARS = 200
BUDGET_LIMIT = 8
BUDGET_WINDOW_SECONDS = 24 * 60 * 60
RETRY_HISTORY = 50
EVENT_LIMIT = 100
METADATA_TIMEOUT = 300
START_TIMEOUT = 60

AGENT_DIR = Path("/var/lib/vasher/agent")
STATUS_PATH = Path("/var/lib/vasher/dashboard/status.json")
EVENTS_PATH = Path("/var/lib/vasher/dashboard/events.json")
FAULT_PATH = Path("/var/lib/vasher/monitor/storage-fault.json")
RETRY_PATH = Path("/var/lib/vasher/monitor/retry.json")
LOCK_PATH = Path("/var/lib/vasher/prebuild.lock")
CANDIDATE_WORKTREE = Path("/var/lib/vasher/worktrees/candidate")
AGENT_HOME = "/var/lib/vasher-agent"
SYSTEM_BIN = "/run/current-system/sw/bin"
SYSTEMCTL = SYSTEM_BIN + "/systemctl"
NIX = SYSTEM_BIN + "/nix"

RETRY_UNIT = "vasher-prebuild-retry.service"
NARROW_UNIT = "vasher-prebuild-narrow.service"
ALLOWED_UNITS = (RETRY_UNIT, NARROW_UNIT)
BUILD_VERBS = ("retry-exact", "narrow-inputs")
RETRY_STATES = ("failed", "needs-attention")

REVISION_RE = re.compile(r"^[0-9a-f]{40}$")
INPUT_RE = re.compile(r"^[A-Za-z0-9][A-Za-z0-9._-]{0,63}$")
DATE_RE = re.compile(r"^\d{4}-\d{2}-\d{2}$")
REASON_RE = re.compile(r"^[^\x00-\x1f\x7f]+$")


def probe_lock(path: Path) -> bool:
    """Reports whether the prebuild lock is held, without blocking on it.

    A shared probe conflicts with the exclusive lock the prebuild script
    takes, so a running build is visible, and two probes never fight. An
    unreadable lock counts as busy: the channel fails closed.
    """
    try:
        descriptor = os.open(path, os.O_RDONLY)
    except FileNotFoundError:
        return False
    except OSError:
        return True
    try:
        fcntl.flock(descriptor, fcntl.LOCK_SH | fcntl.LOCK_NB)
    except OSError:
        return True
    else:
        fcntl.flock(descriptor, fcntl.LOCK_UN)
        return False
    finally:
        os.close(descriptor)


def read_flake_inputs(worktree: Path) -> frozenset[str] | None:
    """Returns the root flake input names of the candidate worktree.

    Returns None when the worktree is absent or the metadata is unusable, so
    that "unknown" never reads as "nothing is known": the caller rejects.
    """
    if not (worktree / "flake.nix").is_file():
        return None
    try:
        result = subprocess.run(
            [NIX, "flake", "metadata", "--json", "--no-write-lock-file",
             str(worktree)],
            capture_output=True,
            stdin=subprocess.DEVNULL,
            timeout=METADATA_TIMEOUT,
            check=False,
            env={
                "HOME": AGENT_HOME,
                "PATH": SYSTEM_BIN,
                "NIX_CONFIG": "experimental-features = nix-command flakes",
            },
        )
    except (OSError, subprocess.SubprocessError):
        return None
    if result.returncode != 0:
        return None
    try:
        metadata = json.loads(result.stdout)
    except (json.JSONDecodeError, UnicodeDecodeError):
        return None
    if not isinstance(metadata, dict):
        return None
    nodes = metadata.get("locks", {})
    nodes = nodes.get("nodes", {}) if isinstance(nodes, dict) else {}
    root = nodes.get("root", {}) if isinstance(nodes, dict) else {}
    inputs = root.get("inputs", {}) if isinstance(root, dict) else {}
    if not isinstance(inputs, dict):
        return None
    return frozenset(name for name in inputs if isinstance(name, str))


def start_unit(unit: str) -> None:
    if unit not in ALLOWED_UNITS:
        raise ValueError(f"unit {unit} is not startable from the channel")
    subprocess.run(
        [SYSTEMCTL, "start", "--no-block", unit],
        capture_output=True,
        stdin=subprocess.DEVNULL,
        timeout=START_TIMEOUT,
        check=True,
    )


@dataclass(frozen=True)
class Context:
    now: float
    agent_dir: Path = AGENT_DIR
    status_path: Path = STATUS_PATH
    events_path: Path = EVENTS_PATH
    fault_path: Path = FAULT_PATH
    retry_path: Path = RETRY_PATH
    lock_path: Path = LOCK_PATH
    worktree: Path = CANDIDATE_WORKTREE
    lock_busy: Callable[[Path], bool] = field(default=probe_lock)
    flake_inputs: Callable[[Path], frozenset[str] | None] = field(
        default=read_flake_inputs
    )
    start_unit: Callable[[str], None] = field(default=start_unit)

    @property
    def holds_path(self) -> Path:
        return self.agent_dir / "holds.json"

    @property
    def narrow_request_path(self) -> Path:
        return self.agent_dir / "narrow-request.json"

    @property
    def verbs_path(self) -> Path:
        return self.agent_dir / "verbs.json"

    @property
    def today(self):
        return datetime.fromtimestamp(self.now, timezone.utc).date()

    @property
    def timestamp(self) -> str:
        return time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime(self.now))


@dataclass(frozen=True)
class Response:
    accepted: bool
    reason: str
    event_id: str | None
    code: int

    def payload(self) -> dict[str, object]:
        return {
            "accepted": self.accepted,
            "reason": self.reason,
            "eventId": self.event_id,
        }


@dataclass(frozen=True)
class Plan:
    """One accepted action: files to write, then at most one unit to start."""

    writes: tuple[tuple[Path, object, int], ...] = ()
    unit: str | None = None
    revision: str | None = None
    retry_revision: str | None = None


@dataclass(frozen=True)
class Ledger:
    accepted: tuple[dict[str, object], ...] = ()
    retries: dict[str, int] = field(default_factory=dict)


def atomic_json(path: Path, value: object, mode: int = 0o600) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_name(f".{path.name}.tmp")
    temporary.write_text(json.dumps(value, separators=(",", ":")) + "\n")
    temporary.chmod(mode)
    temporary.replace(path)


def load_json(path: Path) -> object:
    try:
        return json.loads(path.read_text())
    except (OSError, json.JSONDecodeError, UnicodeDecodeError):
        return None


def append_event(path: Path, event: dict[str, object]) -> None:
    events = load_json(path)
    if not isinstance(events, list):
        events = []
    atomic_json(path, [event, *events][:EVENT_LIMIT], mode=0o644)


def load_ledger(path: Path) -> Ledger:
    value = load_json(path)
    if not isinstance(value, dict):
        return Ledger()
    raw_accepted = value.get("accepted")
    accepted = tuple(
        entry
        for entry in (raw_accepted if isinstance(raw_accepted, list) else [])
        if isinstance(entry, dict) and isinstance(entry.get("at"), (int, float))
        and not isinstance(entry.get("at"), bool)
    )
    raw_retries = value.get("retries")
    retries = {
        name: count
        for name, count in (
            raw_retries.items() if isinstance(raw_retries, dict) else []
        )
        if isinstance(name, str) and isinstance(count, int)
        and not isinstance(count, bool)
    }
    return Ledger(accepted=accepted, retries=retries)


def spent(ledger: Ledger, now: float) -> int:
    window = now - BUDGET_WINDOW_SECONDS
    return sum(1 for entry in ledger.accepted if entry["at"] >= window)


def record_verb(
    ctx: Context, ledger: Ledger, event_id: str, verb: str, plan: Plan
) -> None:
    window = ctx.now - BUDGET_WINDOW_SECONDS
    entries = [entry for entry in ledger.accepted if entry["at"] >= window]
    entries.append(
        {"id": event_id, "at": ctx.now, "verb": verb, "revision": plan.revision}
    )
    retries = dict(ledger.retries)
    if plan.retry_revision is not None:
        retries[plan.retry_revision] = retries.get(plan.retry_revision, 0) + 1
        if len(retries) > RETRY_HISTORY:
            retries = dict(list(retries.items())[-RETRY_HISTORY:])
    atomic_json(ctx.verbs_path, {"accepted": entries, "retries": retries}, 0o600)


def emit(
    ctx: Context,
    event_id: str,
    verb: str,
    accepted: bool,
    reason: str,
    revision: str | None,
) -> None:
    event = {
        "id": event_id,
        "timestamp": ctx.timestamp,
        "revision": revision,
        "type": "agent-verb",
        "severity": "info" if accepted else "warning",
        "reason": reason,
        "metrics": None,
        "action": verb,
        "summary": "",
        "source": "agent",
        "verb": verb,
        "accepted": accepted,
    }
    try:
        append_event(ctx.events_path, event)
    except OSError:
        # The ledger is a report, not the decision. A full or read-only
        # dashboard directory must not turn an answered request into a crash.
        return


def reject(
    ctx: Context, verb: str, reason: str, revision: str | None = None
) -> Response:
    event_id = uuid.uuid4().hex
    emit(ctx, event_id, verb, False, reason, revision)
    return Response(accepted=False, reason=reason, event_id=event_id, code=1)


def is_revision(value: object) -> bool:
    return isinstance(value, str) and REVISION_RE.fullmatch(value) is not None


def is_input_name(value: object) -> bool:
    return isinstance(value, str) and INPUT_RE.fullmatch(value) is not None


def parse_date(value: object):
    if not isinstance(value, str) or DATE_RE.fullmatch(value) is None:
        return None
    try:
        return datetime.strptime(value, "%Y-%m-%d").date()
    except ValueError:
        return None


def load_holds(path: Path) -> dict[str, object]:
    value = load_json(path)
    if not isinstance(value, dict):
        return {}
    return {
        name: record
        for name, record in value.items()
        if isinstance(name, str) and isinstance(record, dict)
    }


def check_retry(request: dict, ctx: Context, ledger: Ledger) -> Plan | str:
    revision = request.get("revision")
    if not is_revision(revision):
        return "revision"
    status = load_json(ctx.status_path)
    if not isinstance(status, dict):
        return "state"
    if status.get("state") not in RETRY_STATES:
        return "state"
    base = status.get("baseRevision")
    recorded = status.get("revision")
    if not is_revision(base) or not is_revision(recorded):
        return "state"
    if revision != recorded:
        return "revision"
    if ledger.retries.get(revision, 0):
        return "retry-budget"
    return Plan(
        writes=(
            (ctx.retry_path, {"baseRevision": base, "revision": revision}, 0o644),
        ),
        unit=RETRY_UNIT,
        revision=revision,
        retry_revision=revision,
    )


def check_narrow(request: dict, ctx: Context, ledger: Ledger) -> Plan | str:
    base = request.get("base")
    if not is_revision(base):
        return "base"
    status = load_json(ctx.status_path)
    if not isinstance(status, dict) or status.get("baseRevision") != base:
        return "base"
    inputs = request.get("inputs")
    if not isinstance(inputs, list) or not 1 <= len(inputs) <= MAX_INPUTS:
        return "inputs"
    if not all(is_input_name(name) for name in inputs):
        return "inputs"
    if len(set(inputs)) != len(inputs):
        return "inputs"
    known = ctx.flake_inputs(ctx.worktree)
    if known is None or not set(inputs) <= known:
        return "inputs"
    return Plan(
        writes=(
            (ctx.narrow_request_path, {"base": base, "inputs": list(inputs)}, 0o644),
        ),
        unit=NARROW_UNIT,
        revision=base,
    )


def check_hold(request: dict, ctx: Context, ledger: Ledger) -> Plan | str:
    name = request.get("input")
    if not is_input_name(name):
        return "inputs"
    known = ctx.flake_inputs(ctx.worktree)
    if known is None or name not in known:
        return "inputs"
    revision = request.get("revision")
    if not is_revision(revision):
        return "hold"
    expires = parse_date(request.get("expires"))
    if expires is None:
        return "hold"
    today = ctx.today
    if expires < today or expires > today + timedelta(days=MAX_HOLD_DAYS):
        return "hold"
    reason = request.get("reason")
    if not isinstance(reason, str):
        return "hold"
    text = reason.strip()
    if not text or len(text) > MAX_REASON_CHARS or REASON_RE.fullmatch(text) is None:
        return "hold"
    holds = load_holds(ctx.holds_path)
    holds[name] = {
        "revision": revision,
        "expires": expires.isoformat(),
        "reason": text,
        "createdAt": ctx.timestamp,
    }
    return Plan(writes=((ctx.holds_path, holds, 0o644),), revision=revision)


def check_release(request: dict, ctx: Context, ledger: Ledger) -> Plan | str:
    name = request.get("input")
    if not is_input_name(name):
        return "inputs"
    holds = load_holds(ctx.holds_path)
    if name not in holds:
        return "hold"
    remaining = {key: value for key, value in holds.items() if key != name}
    return Plan(writes=((ctx.holds_path, remaining, 0o644),))


CHECKS: dict[str, Callable[[dict, Context, Ledger], "Plan | str"]] = {
    "retry-exact": check_retry,
    "narrow-inputs": check_narrow,
    "hold-input": check_hold,
    "release-input": check_release,
}


def handle(request: dict, ctx: Context) -> Response:
    verb = request.get("verb")
    if not isinstance(verb, str) or verb not in CHECKS:
        return Response(accepted=False, reason="verb", event_id=None, code=2)
    # A suspect disk rejects every verb. Only an operator clears the fault
    # file; this program has no path that removes it.
    if ctx.fault_path.exists():
        return reject(ctx, verb, "storage-fault")
    if verb in BUILD_VERBS and ctx.lock_busy(ctx.lock_path):
        return reject(ctx, verb, "busy")
    ledger = load_ledger(ctx.verbs_path)
    outcome = CHECKS[verb](request, ctx, ledger)
    if isinstance(outcome, str):
        return reject(ctx, verb, outcome)
    if spent(ledger, ctx.now) >= BUDGET_LIMIT:
        return reject(ctx, verb, "budget", outcome.revision)
    event_id = uuid.uuid4().hex
    # The budget is spent before the action runs: a crash between the two
    # costs one verb, while the reverse would let a crash loop spend none.
    record_verb(ctx, ledger, event_id, verb, outcome)
    for path, value, mode in outcome.writes:
        atomic_json(path, value, mode)
    if outcome.unit is not None:
        try:
            ctx.start_unit(outcome.unit)
        except Exception:
            return reject(ctx, verb, "unit", outcome.revision)
    emit(ctx, event_id, verb, True, "accepted", outcome.revision)
    return Response(accepted=True, reason="accepted", event_id=event_id, code=0)


def parse_request(data: bytes) -> dict | None:
    if len(data) > MAX_REQUEST_BYTES:
        return None
    try:
        value = json.loads(data.decode("utf-8"))
    except (UnicodeDecodeError, json.JSONDecodeError):
        return None
    return value if isinstance(value, dict) else None


def process(data: bytes, ctx: Context) -> tuple[dict[str, object], int]:
    request = parse_request(data)
    if request is None:
        return {"accepted": False, "reason": "malformed", "eventId": None}, 2
    response = handle(request, ctx)
    return response.payload(), response.code


def main() -> int:
    # SSH_ORIGINAL_COMMAND is deliberately unread: the forced command fixes the
    # program, and the request body is the only input.
    data = sys.stdin.buffer.read(MAX_REQUEST_BYTES + 1)
    payload, code = process(data, Context(now=time.time()))
    sys.stdout.write(json.dumps(payload, separators=(",", ":")) + "\n")
    return code


if __name__ == "__main__":
    raise SystemExit(main())
