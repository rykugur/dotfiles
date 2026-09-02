#!/usr/bin/env python3
from __future__ import annotations

import json
from dataclasses import dataclass
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

STATE_PATH = Path("/var/lib/vasher/monitor/state.json")
EVENTS_PATH = Path("/var/lib/vasher/dashboard/events.json")
RETRY_PATH = Path("/var/lib/vasher/monitor/retry.json")

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


def _timer(started: float | None, active: bool, now: float) -> float | None:
    if not active:
        return None
    return now if started is None else started


def evaluate(
    state: MonitorState, sample: Sample
) -> tuple[MonitorState, Decision | None]:
    memory_low = sample.mem_available < MEMORY_LIMIT or sample.swap_free < SWAP_LIMIT
    state.memory_since = _timer(state.memory_since, memory_low, sample.at)
    state.disk_since = _timer(
        state.disk_since, sample.disk_free < DISK_LIMIT, sample.at
    )

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
    if (
        state.memory_since is not None
        and sample.at - state.memory_since >= MEMORY_SECONDS
    ):
        reason = "memory"
    elif state.disk_since is not None and sample.at - state.disk_since >= DISK_SECONDS:
        reason = "disk"
    elif (
        state.stall_since is not None
        and sample.at - state.stall_since >= STALL_SECONDS
    ):
        reason = "stall"

    if reason is None:
        return state, None
    action: Action = "stop-final" if state.retry_count else "stop"
    return state, Decision(action, reason)


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
