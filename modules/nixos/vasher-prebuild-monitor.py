#!/usr/bin/env python3
from __future__ import annotations

import json
import os
import re
import subprocess
import time
import urllib.error
import urllib.request
import uuid
from dataclasses import asdict, dataclass, replace
from pathlib import Path
from typing import Callable, Literal

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
SYSTEMCTL = "/run/current-system/sw/bin/systemctl"
STATUS_PATH = Path("/var/lib/vasher/dashboard/status.json")
LOG_PATH = Path("/var/lib/vasher/dashboard/current.log")
PRESSURE_PATH = Path("/proc/pressure/memory")
BOOT_ID_PATH = Path("/proc/sys/kernel/random/boot_id")
CANDIDATE_WORKTREE = "/var/lib/vasher/worktrees/candidate"

ACTIVE_UNITS = (
    "vasher-prebuild-candidate.service",
    "vasher-prebuild-retry.service",
)
STOP_UNITS = {
    "vasher-prebuild-candidate.service",
    "vasher-prebuild-retry.service",
}
REVISION_RE = re.compile(r"^[0-9a-f]{40}$")
RECOVERY_PHASES = {"stopping", "cleaning", "retrying"}
RETRY_WAIT_SECONDS = 600
SAMPLE_INTERVAL = 30
OPENROUTER_URL = "https://openrouter.ai/api/v1/chat/completions"
OPENROUTER_MODEL = "deepseek/deepseek-v4-flash"
SUMMARY_EVENTS = {
    "safety-stop",
    "build-failed",
    "build-succeeded",
    "needs-attention",
}
SECRET_PATTERNS = (
    re.compile(r"(?im)^(authorization:\s*(?:bearer|token)\s+)\S+"),
    re.compile(r"(?im)^(x-api-key:\s*)\S+"),
    re.compile(r"(?i)([?&](?:access_token|token|key)=)[^&\s]+"),
)

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
    cleaning_since: float | None = None

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


def read_worktree_head(worktree: Path) -> str | None:
    git_entry = worktree / ".git"
    try:
        if git_entry.is_file():
            gitdir = None
            for line in git_entry.read_text(encoding="utf-8").splitlines():
                stripped = line.strip()
                if stripped.lower().startswith("gitdir:"):
                    gitdir = Path(stripped.split(":", 1)[1].strip())
                    if not gitdir.is_absolute():
                        gitdir = git_entry.parent / gitdir
                    break
            if gitdir is None:
                return None
        elif git_entry.is_dir():
            gitdir = git_entry
        else:
            return None
        head = (gitdir / "HEAD").read_text(encoding="utf-8").strip()
    except OSError:
        return None
    if REVISION_RE.fullmatch(head):
        return head
    return None


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


def build_evidence(event: dict[str, object], log_text: str, secrets: list[str]) -> str:
    lines = redact(bounded_log(log_text), secrets).splitlines()
    while True:
        document = {
            "revision": event.get("revision", ""),
            "type": event.get("type", ""),
            "reason": event.get("reason", ""),
            "action": event.get("action", ""),
            "metrics": event.get("metrics", {}),
            "exitCode": event.get("exitCode"),
            "timestamp": event.get("timestamp", ""),
            "log": "\n".join(lines),
        }
        encoded = json.dumps(document, separators=(",", ":"))
        if len(encoded.encode()) <= 32 * 1024 or not lines:
            return redact(encoded, secrets)
        lines = lines[1:]


class InferenceError(Exception):
    pass


@dataclass(frozen=True)
class ModelRequest:
    url: str
    timeout: int
    body: dict[str, object]
    headers: dict[str, str]


class UrllibTransport:
    def send(self, request: ModelRequest) -> dict[str, object]:
        payload = json.dumps(request.body).encode()
        http_request = urllib.request.Request(
            request.url,
            data=payload,
            headers=request.headers,
            method="POST",
        )
        with urllib.request.urlopen(http_request, timeout=request.timeout) as response:
            return json.loads(response.read().decode())


class OpenRouterClient:
    def __init__(self, key_path: Path, transport: object | None = None) -> None:
        self.key_path = key_path
        self.transport = transport or UrllibTransport()

    def summarize(self, evidence: str) -> str:
        key = self.key_path.read_text().strip()
        body = {
            "model": OPENROUTER_MODEL,
            "max_tokens": 512,
            "messages": [
                {
                    "role": "system",
                    "content": (
                        "Summarize this Vasher prebuild event for its operator. "
                        "State the observed condition, automatic action, and final state. "
                        "Do not provide commands or request more access."
                    ),
                },
                {"role": "user", "content": redact(evidence, [key])},
            ],
        }
        headers = {
            "content-type": "application/json",
            "Authorization": f"Bearer {key}",
        }
        request = ModelRequest(
            url=OPENROUTER_URL,
            timeout=30,
            body=body,
            headers=headers,
        )
        try:
            payload = self.transport.send(request)
        except urllib.error.HTTPError:
            raise InferenceError("http-error") from None
        except TimeoutError:
            raise InferenceError("timeout") from None
        except urllib.error.URLError:
            raise InferenceError("url-error") from None
        except json.JSONDecodeError:
            raise InferenceError("invalid-json") from None
        try:
            text = payload["choices"][0]["message"]["content"]
        except (KeyError, IndexError, TypeError):
            raise InferenceError("invalid-response") from None
        if not isinstance(text, str):
            raise InferenceError("invalid-response")
        return text[:4096]


class InvalidStatus(Exception):
    pass


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


def systemd_values(
    runner: Runner, unit: str, properties: tuple[str, ...]
) -> dict[str, str]:
    result = runner.run(
        [SYSTEMCTL, "show", unit, *[f"--property={item}" for item in properties]]
    )
    return dict(
        line.split("=", 1) for line in result.stdout.splitlines() if "=" in line
    )


def _int_or_zero(value: str | None) -> int:
    try:
        return int(value or 0)
    except ValueError:
        return 0


def _cpu_seconds(value: str | None) -> float:
    return _int_or_zero(value) / 1_000_000_000


class SystemReader:
    def __init__(
        self,
        runner: Runner,
        *,
        meminfo_path: Path = Path("/proc/meminfo"),
        pressure_path: Path = PRESSURE_PATH,
        status_path: Path = STATUS_PATH,
        log_path: Path = LOG_PATH,
        statvfs: Callable[[str], os.statvfs_result] = os.statvfs,
        now: Callable[[], float] = time.monotonic,
        root: str = "/",
    ) -> None:
        self.runner = runner
        self.meminfo_path = meminfo_path
        self.pressure_path = pressure_path
        self.status_path = status_path
        self.log_path = log_path
        self.statvfs = statvfs
        self.now = now
        self.root = root

    def sample(self) -> Sample:
        status = json.loads(self.status_path.read_text())
        base_revision = str(status.get("baseRevision") or "")
        revision = str(status.get("revision") or "")
        if not REVISION_RE.fullmatch(base_revision) or not REVISION_RE.fullmatch(
            revision
        ):
            raise InvalidStatus("status revisions must be 40-character hex")
        status_state = str(status.get("state") or "")
        meminfo = read_meminfo(self.meminfo_path)
        vfs = self.statvfs(self.root)
        try:
            log_size = self.log_path.stat().st_size
        except FileNotFoundError:
            log_size = 0
        nix = systemd_values(
            self.runner, "nix-daemon.service", ("MemoryCurrent", "CPUUsageNSec")
        )
        active_unit = None
        unit_cpu = 0.0
        if status_state not in {"success", "failed"}:
            for unit in ACTIVE_UNITS:
                values = systemd_values(
                    self.runner, unit, ("ActiveState", "CPUUsageNSec")
                )
                if values.get("ActiveState") in {"active", "activating"}:
                    active_unit = unit
                    unit_cpu = _cpu_seconds(values.get("CPUUsageNSec"))
                    break
        exit_code = status.get("exitCode")
        return Sample(
            at=self.now(),
            active_unit=active_unit,
            mode=str(status.get("mode") or ""),
            status_state=status_state,
            status_updated_at=str(status.get("updatedAt") or ""),
            exit_code=exit_code if isinstance(exit_code, int) else None,
            base_revision=base_revision,
            revision=revision,
            mem_available=meminfo.get("MemAvailable", 0),
            swap_free=meminfo.get("SwapFree", 0),
            disk_free=vfs.f_bavail * vfs.f_frsize,
            memory_pressure_full=read_memory_pressure(self.pressure_path),
            nix_memory=_int_or_zero(nix.get("MemoryCurrent")),
            combined_cpu_seconds=unit_cpu + _cpu_seconds(nix.get("CPUUsageNSec")),
            log_size=log_size,
        )


class Controller:
    def __init__(
        self,
        runner: Runner,
        state_path: Path,
        events_path: Path,
        retry_path: Path,
        boot_id: str | None = None,
        reader: SystemReader | None = None,
        model: object | None = None,
        log_path: Path | None = None,
    ) -> None:
        self.runner = runner
        self.state_path = state_path
        self.events_path = events_path
        self.retry_path = retry_path
        self.reader = reader
        self.model = model
        self.log_path = LOG_PATH if log_path is None else log_path
        self.sleep = getattr(runner, "sleep", time.sleep)
        self._recovering = False
        self.boot_id = boot_id if boot_id is not None else BOOT_ID_PATH.read_text().strip()
        self.state = self._load_existing()
        if (
            self.state.boot_id
            and self.state.boot_id != self.boot_id
            and self.state.phase in RECOVERY_PHASES
        ):
            self.state.phase = "needs-attention"
            self.state.boot_id = self.boot_id
            self._save()
            self._event(
                None,
                "needs-attention",
                reason="boot-id-changed",
                action="none",
                severity="error",
            )
        elif not self.state.boot_id:
            self.state.boot_id = self.boot_id

    def _load_existing(self) -> MonitorState:
        try:
            return MonitorState(**json.loads(self.state_path.read_text()))
        except (FileNotFoundError, json.JSONDecodeError, TypeError):
            return MonitorState.for_revision("", "")

    def _save(self) -> None:
        atomic_json(self.state_path, asdict(self.state))

    def _event(
        self,
        sample: Sample | None,
        event_type: str,
        *,
        reason: str = "",
        action: str = "",
        severity: str = "info",
        extra: dict[str, object] | None = None,
    ) -> dict[str, object]:
        metrics: dict[str, object] = {}
        revision = self.state.revision
        if sample is not None:
            revision = sample.revision
            metrics = {
                "mem_available": sample.mem_available,
                "swap_free": sample.swap_free,
                "disk_free": sample.disk_free,
                "memory_pressure_full": sample.memory_pressure_full,
                "nix_memory": sample.nix_memory,
                "combined_cpu_seconds": sample.combined_cpu_seconds,
                "log_size": sample.log_size,
            }
        event: dict[str, object] = {
            "id": uuid.uuid4().hex,
            "timestamp": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
            "revision": revision,
            "type": event_type,
            "severity": severity,
            "reason": reason,
            "metrics": metrics,
            "action": action,
            "summary": "",
        }
        if extra:
            event.update(extra)
        append_event(self.events_path, event)
        if (
            event_type in SUMMARY_EVENTS
            and event_type != "safety-stop"
            and not self._recovering
        ):
            self.summarize(event)
        return event

    def record_error(self, message: str) -> None:
        self._event(None, "error", reason=message, severity="error")

    def _update_event(self, event_id: str, changes: dict[str, object]) -> None:
        try:
            events = json.loads(self.events_path.read_text())
        except (FileNotFoundError, json.JSONDecodeError):
            return
        updated = False
        for item in events:
            if item.get("id") == event_id:
                item.update(changes)
                updated = True
                break
        if updated:
            atomic_json(self.events_path, events, mode=0o644)

    def summarize(self, event: dict[str, object]) -> None:
        if self.model is None:
            return
        if event.get("type") not in SUMMARY_EVENTS:
            return
        if event.get("summary") or event.get("inferenceError"):
            return
        event_id = event.get("id")
        if not isinstance(event_id, str) or not event_id:
            return
        try:
            try:
                log_text = self.log_path.read_text()
            except OSError:
                log_text = ""
            secrets: list[str] = []
            key_path = getattr(self.model, "key_path", None)
            if key_path is not None:
                try:
                    secret = Path(key_path).read_text().strip()
                except OSError:
                    secret = ""
                if secret:
                    secrets.append(secret)
            evidence = build_evidence(event, log_text, secrets)
            summary = self.model.summarize(evidence)
            if not isinstance(summary, str):
                raise InferenceError("invalid-response")
            stored = summary[:4096]
            self._update_event(event_id, {"summary": stored})
            event["summary"] = stored
        except Exception as error:
            message = (
                str(error)
                if isinstance(error, InferenceError)
                else type(error).__name__
            )
            self._update_event(event_id, {"inferenceError": message})
            event["inferenceError"] = message

    def _align_state(self, sample: Sample) -> None:
        if (self.state.base_revision, self.state.revision) != (
            sample.base_revision,
            sample.revision,
        ):
            self.state = MonitorState.for_revision(
                sample.base_revision, sample.revision
            )
        self.state.boot_id = self.boot_id

    def _update_nix_safe(self, sample: Sample) -> None:
        if sample.nix_memory < 2 * GIB:
            self.state.nix_safe_since = (
                sample.at if self.state.nix_safe_since is None else self.state.nix_safe_since
            )
        else:
            self.state.nix_safe_since = None

    def _retry_ready(self, sample: Sample) -> bool:
        self._update_nix_safe(sample)
        nix_memory_below_limit_for = (
            0 if self.state.nix_safe_since is None else sample.at - self.state.nix_safe_since
        )
        return (
            sample.mem_available >= 2 * GIB
            and sample.swap_free >= GIB
            and sample.disk_free >= 10 * GIB
            and sample.nix_memory < 2 * GIB
            and nix_memory_below_limit_for >= 60
            and self.state.retry_count == 0
        )

    def _next_sample(self, current: Sample) -> Sample:
        if self.reader is not None:
            observed = self.reader.sample()
            if observed is not None:
                return observed
        return replace(current, at=current.at + SAMPLE_INTERVAL)

    def _needs_attention(self, sample: Sample | None, reason: str) -> None:
        self.state.phase = "needs-attention"
        self._save()
        self._event(
            sample,
            "needs-attention",
            reason=reason,
            action="none",
            severity="error",
        )

    def _worktree_matches(self, sample: Sample) -> bool:
        return read_worktree_head(Path(CANDIDATE_WORKTREE)) == sample.revision

    def _start_retry(self, sample: Sample) -> None:
        if not self._worktree_matches(sample):
            self._needs_attention(sample, "worktree-mismatch")
            return
        self.state.retry_count = 1
        self.state.phase = "retrying"
        self._save()
        atomic_json(
            self.retry_path,
            {
                "baseRevision": sample.base_revision,
                "revision": sample.revision,
            },
            mode=0o644,
        )
        self.runner.run(
            [SYSTEMCTL, "start", "--no-block", "vasher-prebuild-retry.service"],
            check=True,
        )

    def _cleaning_wait_elapsed(self, sample: Sample) -> float:
        if self.state.cleaning_since is None:
            self.state.cleaning_since = sample.at
            self._save()
        return sample.at - self.state.cleaning_since

    def _cleanup_then_retry(self, sample: Sample) -> None:
        self.state.phase = "cleaning"
        if self.state.cleaning_since is None:
            self.state.cleaning_since = sample.at
        self._save()
        try:
            self.runner.run(
                [SYSTEMCTL, "start", "vasher-prebuild-cleanup.service"],
                check=True,
            )
        except subprocess.CalledProcessError:
            self._needs_attention(sample, "cleanup-failed")
            return
        current = self._next_sample(sample)
        while True:
            if self._retry_ready(current):
                self._start_retry(current)
                return
            if self._cleaning_wait_elapsed(current) >= RETRY_WAIT_SECONDS:
                self._needs_attention(current, "retry-precondition")
                return
            self.sleep(SAMPLE_INTERVAL)
            current = self._next_sample(current)

    def _resume_cleaning(self, sample: Sample) -> None:
        if self._retry_ready(sample):
            self._start_retry(sample)
        elif self._cleaning_wait_elapsed(sample) >= RETRY_WAIT_SECONDS:
            self._needs_attention(sample, "retry-precondition")

    def _summarize_pending(self) -> None:
        try:
            events = json.loads(self.events_path.read_text())
        except (FileNotFoundError, json.JSONDecodeError):
            return
        for event in events:
            if event.get("type") in SUMMARY_EVENTS:
                self.summarize(event)

    def recover(self, sample: Sample, decision: Decision) -> None:
        self._align_state(sample)
        unit = sample.active_unit
        if decision.action == "stop-final":
            if unit in STOP_UNITS:
                self.runner.run([SYSTEMCTL, "stop", unit], check=True)
            self._needs_attention(sample, decision.reason)
            return
        if unit in STOP_UNITS:
            self.state.phase = "stopping"
            self._save()
            self._event(
                sample,
                "safety-stop",
                reason=decision.reason,
                action="stop",
                severity="warning",
            )
            self.runner.run([SYSTEMCTL, "stop", unit], check=True)
        elif self.state.phase != "stopping":
            self._needs_attention(sample, "missing-stop-unit")
            return
        self._recovering = True
        try:
            self._cleanup_then_retry(sample)
        finally:
            self._recovering = False
        self._summarize_pending()

    def observe(self, sample: Sample) -> None:
        self._align_state(sample)
        if sample.status_state == "building":
            try:
                events = json.loads(self.events_path.read_text())
            except (FileNotFoundError, json.JSONDecodeError):
                events = []
            if not any(
                event.get("type") == "build-observed"
                and event.get("revision") == sample.revision
                for event in events
            ):
                self._event(sample, "build-observed")
                self._save()
        if (
            sample.status_state in {"success", "failed"}
            and self.state.phase not in {"stopping", "cleaning"}
            and (self.state.phase != "retrying" or sample.mode == "retry")
        ):
            if sample.status_updated_at != self.state.last_terminal_at:
                self.state.last_terminal_at = sample.status_updated_at
                self.state.phase = "complete"
                self._save()
                event_type = (
                    "build-succeeded"
                    if sample.status_state == "success"
                    else "build-failed"
                )
                self._event(
                    sample,
                    event_type,
                    reason=sample.status_state,
                    action="none",
                    extra={"exitCode": sample.exit_code},
                )
            return
        if self.state.phase == "stopping":
            unit = sample.active_unit
            if unit in STOP_UNITS:
                self.runner.run([SYSTEMCTL, "stop", unit], check=True)
            self._recovering = True
            try:
                self._cleanup_then_retry(sample)
            finally:
                self._recovering = False
            self._summarize_pending()
            return
        if sample.active_unit is None:
            if self.state.phase == "cleaning":
                self._recovering = True
                try:
                    self._resume_cleaning(sample)
                finally:
                    self._recovering = False
                self._summarize_pending()
            elif self.state.phase == "retrying":
                self._start_retry(sample)
                self._summarize_pending()
            return
        if self.state.phase in {"needs-attention", "complete"}:
            return
        if self.state.phase == "cleaning":
            self._recovering = True
            try:
                self._resume_cleaning(sample)
            finally:
                self._recovering = False
            self._summarize_pending()
            return
        state, decision = evaluate(self.state, sample)
        self.state = state
        self.state.boot_id = self.boot_id
        self._save()
        if decision is not None:
            self.recover(sample, decision)


def main() -> int:
    runner = Runner()
    reader = SystemReader(runner)
    key_file = os.environ.get("OPENROUTER_API_KEY_FILE")
    model = OpenRouterClient(Path(key_file)) if key_file else None
    controller = Controller(
        runner, STATE_PATH, EVENTS_PATH, RETRY_PATH, model=model
    )
    controller.reader = reader
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


if __name__ == "__main__":
    raise SystemExit(main())
