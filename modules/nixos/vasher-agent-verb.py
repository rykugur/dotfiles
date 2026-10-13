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

Every file the program writes lives in /var/lib/vasher/agent, the one directory
the channel user owns. It reads the status record, the storage fault file and
the prebuild lock, and it can write none of them.

One exclusive lock covers the whole decision, so concurrent sessions on the
same key cannot both spend the same budget slot or both retry one revision.
"""
from __future__ import annotations

import fcntl
import json
import os
import re
import signal
import subprocess
import sys
import syslog
import tempfile
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
REJECTION_LIMIT = 32
REJECTION_HISTORY = 64
BUDGET_WINDOW_SECONDS = 24 * 60 * 60
RETRY_HISTORY = 50
EVENT_LIMIT = 100
METADATA_TIMEOUT = 300
START_TIMEOUT = 60
STDIN_TIMEOUT = 10
LOCK_TIMEOUT = 30.0
LOCK_POLL = 0.02

# The only directory the channel user owns, and the only one it writes.
AGENT_DIR = Path("/var/lib/vasher/agent")
# Read-only inputs. The channel has no write permission on either directory.
STATUS_PATH = Path("/var/lib/vasher/dashboard/status.json")
FAULT_PATH = Path("/var/lib/vasher/monitor/storage-fault.json")
PREBUILD_LOCK_PATH = Path("/var/lib/vasher/prebuild.lock")
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


def log_denied(verb: str, reason: str) -> None:
    """Records a denial in syslog. The request body is never logged.

    Under a forced command standard error reaches the client, not the journal,
    so syslog is the only record an operator can read afterwards.
    """
    try:
        syslog.openlog("vasher-agent-verb", syslog.LOG_PID, syslog.LOG_AUTH)
        syslog.syslog(syslog.LOG_WARNING, f"denied verb={verb} reason={reason}")
    except OSError:
        return


def probe_lock(path: Path) -> bool:
    """Reports whether the prebuild lock is held, without blocking on it.

    A shared probe conflicts with the exclusive lock the prebuild script
    takes, so a running build is visible, two probes never fight, and the lock
    is never stolen. An unreadable lock counts as busy: the channel fails
    closed.
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


def acquire_channel_lock(path: Path, timeout: float) -> int | None:
    """Takes the channel's own exclusive lock, or gives up after timeout.

    The file is distinct from the prebuild lock, which the channel only ever
    probes, so the two can never deadlock.
    """
    try:
        path.parent.mkdir(parents=True, exist_ok=True)
        descriptor = os.open(path, os.O_RDWR | os.O_CREAT, 0o600)
    except OSError:
        return None
    deadline = time.monotonic() + timeout
    while True:
        try:
            fcntl.flock(descriptor, fcntl.LOCK_EX | fcntl.LOCK_NB)
            return descriptor
        except OSError:
            if time.monotonic() >= deadline:
                os.close(descriptor)
                return None
            time.sleep(LOCK_POLL)


def read_flake_inputs(worktree: Path) -> frozenset[str] | None:
    """Returns the root flake input names of the candidate worktree.

    Returns None when the worktree is absent or the metadata is unusable, so
    that "unknown" never reads as "nothing is known": the caller rejects. This
    is the one expensive check, so it runs only after every cheap one passes.
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
    locks = metadata.get("locks")
    nodes = locks.get("nodes") if isinstance(locks, dict) else None
    root = nodes.get("root") if isinstance(nodes, dict) else None
    inputs = root.get("inputs") if isinstance(root, dict) else None
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
    fault_path: Path = FAULT_PATH
    prebuild_lock_path: Path = PREBUILD_LOCK_PATH
    worktree: Path = CANDIDATE_WORKTREE
    lock_timeout: float = LOCK_TIMEOUT
    lock_busy: Callable[[Path], bool] = field(default=probe_lock)
    flake_inputs: Callable[[Path], frozenset[str] | None] = field(
        default=read_flake_inputs
    )
    start_unit: Callable[[str], None] = field(default=start_unit)
    log: Callable[[str, str], None] = field(default=log_denied)

    # Every writable path is derived from agent_dir and nothing else.
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
    def retry_path(self) -> Path:
        return self.agent_dir / "retry.json"

    @property
    def events_path(self) -> Path:
        return self.agent_dir / "events.json"

    @property
    def channel_lock_path(self) -> Path:
        return self.agent_dir / "channel.lock"

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
    rejected: tuple[dict[str, object], ...] = ()
    retries: dict[str, int] = field(default_factory=dict)
    corrupt: bool = False


def atomic_json(path: Path, value: object, mode: int = 0o600) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    descriptor, name = tempfile.mkstemp(dir=path.parent, prefix=f".{path.name}.")
    temporary = Path(name)
    try:
        with os.fdopen(descriptor, "w") as handle:
            handle.write(json.dumps(value, separators=(",", ":")) + "\n")
        os.chmod(temporary, mode)
        os.replace(temporary, path)
    except BaseException:
        temporary.unlink(missing_ok=True)
        raise


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


def _entries(value: object) -> tuple[dict[str, object], ...]:
    return tuple(
        entry
        for entry in (value if isinstance(value, list) else [])
        if isinstance(entry, dict)
        and isinstance(entry.get("at"), (int, float))
        and not isinstance(entry.get("at"), bool)
    )


def load_ledger(path: Path) -> Ledger:
    """Reads the durable counters.

    A missing file is a fresh budget. A file that exists but cannot be read or
    parsed is corrupt, which counts as an exhausted budget: a damaged ledger
    must never hand out a free allowance.
    """
    try:
        value = json.loads(path.read_text())
    except FileNotFoundError:
        return Ledger()
    except (OSError, json.JSONDecodeError, UnicodeDecodeError):
        return Ledger(corrupt=True)
    if not isinstance(value, dict):
        return Ledger(corrupt=True)
    raw_retries = value.get("retries")
    retries = {
        name: count
        for name, count in (
            raw_retries.items() if isinstance(raw_retries, dict) else []
        )
        if isinstance(name, str)
        and isinstance(count, int)
        and not isinstance(count, bool)
    }
    return Ledger(
        accepted=_entries(value.get("accepted")),
        rejected=_entries(value.get("rejected")),
        retries=retries,
    )


def window_count(entries: tuple[dict[str, object], ...], now: float) -> int:
    window = now - BUDGET_WINDOW_SECONDS
    return sum(1 for entry in entries if entry["at"] >= window)


def _in_window(
    entries: tuple[dict[str, object], ...], now: float
) -> list[dict[str, object]]:
    window = now - BUDGET_WINDOW_SECONDS
    return [entry for entry in entries if entry["at"] >= window]


def write_ledger(
    ctx: Context,
    accepted: list[dict[str, object]],
    rejected: list[dict[str, object]],
    retries: dict[str, int],
) -> None:
    atomic_json(
        ctx.verbs_path,
        {"accepted": accepted, "rejected": rejected[-REJECTION_HISTORY:],
         "retries": retries},
        0o600,
    )


def record_accept(
    ctx: Context, ledger: Ledger, event_id: str, verb: str, plan: Plan
) -> None:
    accepted = _in_window(ledger.accepted, ctx.now)
    accepted.append(
        {"id": event_id, "at": ctx.now, "verb": verb, "revision": plan.revision}
    )
    retries = dict(ledger.retries)
    if plan.retry_revision is not None:
        retries[plan.retry_revision] = retries.get(plan.retry_revision, 0) + 1
        if len(retries) > RETRY_HISTORY:
            retries = dict(list(retries.items())[-RETRY_HISTORY:])
    write_ledger(ctx, accepted, _in_window(ledger.rejected, ctx.now), retries)


def record_reject(
    ctx: Context, ledger: Ledger, event_id: str, verb: str, reason: str
) -> None:
    rejected = _in_window(ledger.rejected, ctx.now)
    rejected.append(
        {"id": event_id, "at": ctx.now, "verb": verb, "reason": reason}
    )
    write_ledger(
        ctx,
        _in_window(ledger.accepted, ctx.now),
        rejected,
        dict(ledger.retries),
    )


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
        # The ledger is a report, not the decision. A full directory must not
        # turn an answered request into a crash.
        return


def deny(
    ctx: Context,
    ledger: Ledger | None,
    verb: str,
    reason: str,
    revision: str | None = None,
    record: bool = True,
) -> Response:
    event_id = uuid.uuid4().hex
    if ledger is not None and record:
        try:
            record_reject(ctx, ledger, event_id, verb, reason)
        except OSError:
            pass
    emit(ctx, event_id, verb, False, reason, revision)
    ctx.log(verb, reason)
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


#
# Each verb is one cheap validator and one builder. The validator reads only
# local files and the request; the builder may consult the flake metadata,
# which costs a nix evaluation, so it runs only after the budget check.
#


def validate_retry(request: dict, ctx: Context, ledger: Ledger) -> str | None:
    revision = request.get("revision")
    if not is_revision(revision):
        return "revision"
    status = load_json(ctx.status_path)
    if not isinstance(status, dict):
        return "state"
    if status.get("state") not in RETRY_STATES:
        return "state"
    if not is_revision(status.get("baseRevision")) or not is_revision(
        status.get("revision")
    ):
        return "state"
    if revision != status.get("revision"):
        return "revision"
    if ledger.retries.get(revision, 0):
        return "retry-budget"
    return None


def build_retry(request: dict, ctx: Context) -> Plan | str:
    revision = request["revision"]
    status = load_json(ctx.status_path)
    if not isinstance(status, dict) or not is_revision(status.get("baseRevision")):
        return "state"
    base = status["baseRevision"]
    return Plan(
        writes=(
            (ctx.retry_path, {"baseRevision": base, "revision": revision}, 0o644),
        ),
        unit=RETRY_UNIT,
        revision=revision,
        retry_revision=revision,
    )


def validate_narrow(request: dict, ctx: Context, ledger: Ledger) -> str | None:
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
    return None


def build_narrow(request: dict, ctx: Context) -> Plan | str:
    inputs = list(request["inputs"])
    known = ctx.flake_inputs(ctx.worktree)
    if known is None or not set(inputs) <= known:
        return "inputs"
    return Plan(
        writes=(
            (
                ctx.narrow_request_path,
                {"base": request["base"], "inputs": inputs},
                0o644,
            ),
        ),
        unit=NARROW_UNIT,
        revision=request["base"],
    )


def validate_hold(request: dict, ctx: Context, ledger: Ledger) -> str | None:
    if not is_input_name(request.get("input")):
        return "inputs"
    if not is_revision(request.get("revision")):
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
    return None


def build_hold(request: dict, ctx: Context) -> Plan | str:
    name = request["input"]
    known = ctx.flake_inputs(ctx.worktree)
    if known is None or name not in known:
        return "inputs"
    holds = load_holds(ctx.holds_path)
    holds[name] = {
        "revision": request["revision"],
        "expires": parse_date(request["expires"]).isoformat(),
        "reason": request["reason"].strip(),
        "createdAt": ctx.timestamp,
    }
    return Plan(
        writes=((ctx.holds_path, holds, 0o644),), revision=request["revision"]
    )


def validate_release(request: dict, ctx: Context, ledger: Ledger) -> str | None:
    if not is_input_name(request.get("input")):
        return "inputs"
    return None


def build_release(request: dict, ctx: Context) -> Plan | str:
    name = request["input"]
    holds = load_holds(ctx.holds_path)
    if name not in holds:
        return "hold"
    remaining = {key: value for key, value in holds.items() if key != name}
    return Plan(writes=((ctx.holds_path, remaining, 0o644),))


CHECKS: dict[
    str,
    tuple[
        Callable[[dict, Context, Ledger], "str | None"],
        Callable[[dict, Context], "Plan | str"],
    ],
] = {
    "retry-exact": (validate_retry, build_retry),
    "narrow-inputs": (validate_narrow, build_narrow),
    "hold-input": (validate_hold, build_hold),
    "release-input": (validate_release, build_release),
}


def decide(request: dict, verb: str, ctx: Context) -> Response:
    ledger = load_ledger(ctx.verbs_path)
    if ledger.corrupt:
        # A ledger that cannot be read cannot prove the budget is free, and
        # rewriting it here would hand out a fresh allowance. An operator
        # repairs or removes the file.
        return deny(ctx, None, verb, "budget")
    if window_count(ledger.rejected, ctx.now) >= REJECTION_LIMIT:
        # Lockout probes must not mutate either ledger or extend the rolling
        # window. Syslog remains the bounded operator-visible record.
        ctx.log(verb, "budget")
        return Response(accepted=False, reason="budget", event_id=None, code=1)
    # A suspect disk rejects every verb. Only an operator clears the fault
    # file; the channel user has no write permission on that directory.
    if ctx.fault_path.exists():
        return deny(ctx, ledger, verb, "storage-fault")
    if verb in BUILD_VERBS and ctx.lock_busy(ctx.prebuild_lock_path):
        return deny(ctx, ledger, verb, "busy")
    validate, build = CHECKS[verb]
    reason = validate(request, ctx, ledger)
    if reason is not None:
        return deny(ctx, ledger, verb, reason)
    if window_count(ledger.accepted, ctx.now) >= BUDGET_LIMIT:
        return deny(ctx, ledger, verb, "budget")
    outcome = build(request, ctx)
    if isinstance(outcome, str):
        return deny(ctx, ledger, verb, outcome)
    event_id = uuid.uuid4().hex
    # The budget is spent before the action runs: a crash between the two
    # costs one verb, while the reverse would let a crash loop spend none.
    record_accept(ctx, ledger, event_id, verb, outcome)
    for path, value, mode in outcome.writes:
        atomic_json(path, value, mode)
    if outcome.unit is not None:
        try:
            ctx.start_unit(outcome.unit)
        except Exception:
            return deny(
                ctx, load_ledger(ctx.verbs_path), verb, "unit", outcome.revision
            )
    emit(ctx, event_id, verb, True, "accepted", outcome.revision)
    return Response(accepted=True, reason="accepted", event_id=event_id, code=0)


def handle(request: dict, ctx: Context) -> Response:
    verb = request.get("verb")
    if not isinstance(verb, str) or verb not in CHECKS:
        # The verb is untrusted text until it matches a known name, so the log
        # carries the fixed word instead.
        ctx.log("unknown", "verb")
        return Response(accepted=False, reason="verb", event_id=None, code=2)
    descriptor = acquire_channel_lock(ctx.channel_lock_path, ctx.lock_timeout)
    if descriptor is None:
        # Without the lock the counters cannot be read or written safely, so
        # the request is refused rather than decided on stale numbers.
        return deny(ctx, None, verb, "busy")
    try:
        return decide(request, verb, ctx)
    finally:
        os.close(descriptor)


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
        ctx.log("unknown", "malformed")
        return {"accepted": False, "reason": "malformed", "eventId": None}, 2
    response = handle(request, ctx)
    return response.payload(), response.code


def read_request(timeout: int = STDIN_TIMEOUT) -> bytes:
    """Reads the request body under a deadline.

    A client that opens the session and sends nothing would otherwise pin this
    process and one sshd session for as long as it likes.
    """

    def expire(signum: int, frame: object) -> None:
        raise TimeoutError("timed out reading the request")

    armed = False
    previous = None
    try:
        previous = signal.signal(signal.SIGALRM, expire)
        signal.alarm(timeout)
        armed = True
    except ValueError:
        pass
    try:
        return sys.stdin.buffer.read(MAX_REQUEST_BYTES + 1)
    finally:
        if armed:
            signal.alarm(0)
        if previous is not None:
            signal.signal(signal.SIGALRM, previous)


def main(ctx: Context | None = None) -> int:
    # SSH_ORIGINAL_COMMAND is deliberately unread: the forced command fixes the
    # program, and the request body is the only input.
    context = Context(now=time.time()) if ctx is None else ctx
    try:
        data = read_request()
    except TimeoutError:
        context.log("unknown", "timeout")
        payload: dict[str, object] = {
            "accepted": False,
            "reason": "timeout",
            "eventId": None,
        }
        code = 2
    else:
        payload, code = process(data, context)
    sys.stdout.write(json.dumps(payload, separators=(",", ":")) + "\n")
    sys.stdout.flush()
    return code


if __name__ == "__main__":
    raise SystemExit(main())
