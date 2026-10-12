from __future__ import annotations

import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
import time
import xml.etree.ElementTree as ET
from abc import ABC, abstractmethod
from dataclasses import dataclass
from pathlib import Path
from typing import Sequence


GRAPHICAL_PROCESSES = frozenset(
    {
        "Hyprland",
        "Xorg",
        "Xwayland",
        "gnome-shell",
        "kwin_wayland",
        "sway",
        "weston",
    }
)
INSTALL_MARKER = "install-mode"
CONSOLE_STATE = "bound-consoles.json"


@dataclass(frozen=True)
class UsbDevice:
    vendor_id: str
    product_id: str

    def normalized(self) -> tuple[str, str]:
        return (_normalize_usb_id(self.vendor_id), _normalize_usb_id(self.product_id))


@dataclass(frozen=True)
class Session:
    session_id: str
    username: str
    session_type: str
    state: str


@dataclass(frozen=True)
class Config:
    domain_name: str
    username: str
    gpu: str
    audio: str
    usb_devices: tuple[UsbDevice, ...]
    disk_path: Path
    disk_size_gib: int
    normal_xml: Path
    install_xml: Path
    install_iso_path: Path
    state_directory: Path

    @classmethod
    def from_json(cls, path: Path) -> Config:
        data = json.loads(path.read_text())
        return cls(
            domain_name=str(data["domainName"]),
            username=str(data["username"]),
            gpu=str(data["gpu"]),
            audio=str(data["audio"]),
            usb_devices=tuple(
                UsbDevice(str(device["vendorId"]), str(device["productId"]))
                for device in data["usbDevices"]
            ),
            disk_path=Path(data["diskPath"]),
            disk_size_gib=int(data["diskSizeGiB"]),
            normal_xml=Path(data["normalXml"]),
            install_xml=Path(data["installXml"]),
            install_iso_path=Path(data["installIsoPath"]),
            state_directory=Path(data["stateDirectory"]),
        )


class PreflightError(RuntimeError):
    def __init__(self, diagnostics: Sequence[str]) -> None:
        self.diagnostics = list(diagnostics)
        super().__init__("; ".join(self.diagnostics))


class DomainNotFoundError(RuntimeError):
    pass


class System(ABC):
    def __init__(
        self,
        sysfs_root: Path = Path("/sys"),
        dev_root: Path = Path("/dev"),
    ) -> None:
        self.sysfs_root = sysfs_root
        self.dev_root = dev_root

    def drm_nodes(self, pci_address: str) -> list[Path]:
        pci_device = self.sysfs_root / "bus" / "pci" / "devices" / pci_address
        drm_directory = pci_device / "drm"
        if not drm_directory.is_dir():
            return []

        resolved_device = pci_device.resolve()
        nodes: list[Path] = []
        for entry in sorted(drm_directory.iterdir(), key=lambda path: path.name):
            device_link = entry / "device"
            if not device_link.exists() or device_link.resolve() != resolved_device:
                continue
            node = self.dev_root / "dri" / entry.name
            if node.exists():
                nodes.append(node)
        return nodes

    @abstractmethod
    def graphical_sessions(self, username: str) -> list[Session]:
        raise NotImplementedError

    @abstractmethod
    def process_names(self, username: str) -> set[str]:
        raise NotImplementedError

    @abstractmethod
    def pci_driver(self, address: str) -> str | None:
        raise NotImplementedError

    @abstractmethod
    def drm_owners(self, node: Path) -> tuple[str, ...]:
        raise NotImplementedError

    @abstractmethod
    def bound_consoles(self) -> list[str]:
        raise NotImplementedError

    @abstractmethod
    def save_consoles(self, state_directory: Path, consoles: list[str]) -> None:
        raise NotImplementedError

    @abstractmethod
    def load_consoles(self, state_directory: Path) -> list[str]:
        raise NotImplementedError

    @abstractmethod
    def clear_consoles(self, state_directory: Path) -> None:
        raise NotImplementedError

    @abstractmethod
    def unbind_console(self, console: str) -> None:
        raise NotImplementedError

    @abstractmethod
    def bind_console(self, console: str) -> None:
        raise NotImplementedError

    @abstractmethod
    def unbind_pci(self, address: str) -> None:
        raise NotImplementedError

    @abstractmethod
    def bind_pci(self, address: str, driver: str) -> None:
        raise NotImplementedError

    @abstractmethod
    def release_pci(self, address: str) -> None:
        raise NotImplementedError

    @abstractmethod
    def probe_pci(self, address: str) -> None:
        raise NotImplementedError

    @abstractmethod
    def reset_pci(self, address: str) -> None:
        raise NotImplementedError

    @abstractmethod
    def start_domain(self, domain_name: str, xml_path: Path) -> None:
        raise NotImplementedError

    @abstractmethod
    def wait_domain(self, domain_name: str) -> None:
        raise NotImplementedError

    @abstractmethod
    def stop_domain(self, domain_name: str) -> None:
        raise NotImplementedError

    @abstractmethod
    def path_exists(self, path: Path) -> bool:
        raise NotImplementedError

    @abstractmethod
    def is_readable_file(self, path: Path) -> bool:
        raise NotImplementedError

    @abstractmethod
    def create_sparse_disk(self, path: Path, size_gib: int) -> None:
        raise NotImplementedError

    @abstractmethod
    def copy_atomic(self, source: Path, destination: Path) -> None:
        raise NotImplementedError

    @abstractmethod
    def write_marker(self, path: Path) -> None:
        raise NotImplementedError

    @abstractmethod
    def remove_file(self, path: Path) -> None:
        raise NotImplementedError

    @abstractmethod
    def domain_active(self, domain_name: str) -> bool:
        raise NotImplementedError

    @abstractmethod
    def live_domain_xml(self, domain_name: str) -> str:
        raise NotImplementedError

    @abstractmethod
    def attach_usb_device(
        self, domain_name: str, vendor_id: str, product_id: str
    ) -> None:
        raise NotImplementedError


class RealSystem(System):
    def _run(
        self,
        arguments: Sequence[str],
        *,
        check: bool = True,
    ) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            list(arguments),
            check=check,
            capture_output=True,
            text=True,
        )

    def graphical_sessions(self, username: str) -> list[Session]:
        result = self._run(
            ["loginctl", "list-sessions", "--no-legend", "--no-pager"]
        )
        sessions: list[Session] = []
        for line in result.stdout.splitlines():
            columns = line.split()
            if not columns:
                continue
            session_id = columns[0]
            details = self._run(
                [
                    "loginctl",
                    "show-session",
                    session_id,
                    "--property=Name",
                    "--property=Type",
                    "--property=State",
                    "--no-pager",
                ]
            )
            properties = dict(
                entry.split("=", 1)
                for entry in details.stdout.splitlines()
                if "=" in entry
            )
            if properties.get("Name") != username:
                continue
            sessions.append(
                Session(
                    session_id=session_id,
                    username=username,
                    session_type=properties.get("Type", ""),
                    state=properties.get("State", ""),
                )
            )
        return sessions

    def process_names(self, username: str) -> set[str]:
        result = self._run(
            ["ps", "-u", username, "-o", "comm="],
            check=False,
        )
        if result.returncode not in (0, 1):
            raise RuntimeError(result.stderr.strip() or "failed to inspect processes")
        return {line.strip() for line in result.stdout.splitlines() if line.strip()}

    def pci_driver(self, address: str) -> str | None:
        driver = self.sysfs_root / "bus" / "pci" / "devices" / address / "driver"
        if not driver.exists():
            return None
        return driver.resolve().name

    def drm_owners(self, node: Path) -> tuple[str, ...]:
        fuser = self._run(["fuser", str(node)], check=False)
        if fuser.returncode == 1:
            return ()
        if fuser.returncode != 0:
            raise RuntimeError(fuser.stderr.strip() or f"failed to inspect {node}")
        pids = re.findall(r"\d+", fuser.stdout)
        if not pids:
            return ()
        processes = self._run(
            ["ps", "-p", ",".join(pids), "-o", "pid=,comm="]
        )
        owners = []
        for line in processes.stdout.splitlines():
            fields = line.split(None, 1)
            if len(fields) == 2:
                owners.append(f"{fields[1]}[{fields[0]}]")
        return tuple(sorted(owners))

    def bound_consoles(self) -> list[str]:
        consoles = []
        for console in sorted((self.sysfs_root / "class" / "vtconsole").glob("vtcon*")):
            name = (console / "name").read_text().strip().lower()
            if "frame buffer" not in name:
                continue
            if (console / "bind").read_text().strip() == "1":
                consoles.append(console.name)
        return consoles

    def save_consoles(self, state_directory: Path, consoles: list[str]) -> None:
        state_directory.mkdir(parents=True, exist_ok=True)
        destination = state_directory / CONSOLE_STATE
        temporary = destination.with_suffix(".tmp")
        temporary.write_text(json.dumps(consoles))
        os.replace(temporary, destination)

    def load_consoles(self, state_directory: Path) -> list[str]:
        state_file = state_directory / CONSOLE_STATE
        if not state_file.exists():
            return []
        data = json.loads(state_file.read_text())
        return [str(console) for console in data]

    def clear_consoles(self, state_directory: Path) -> None:
        (state_directory / CONSOLE_STATE).unlink(missing_ok=True)

    def unbind_console(self, console: str) -> None:
        (self.sysfs_root / "class" / "vtconsole" / console / "bind").write_text("0")

    def bind_console(self, console: str) -> None:
        (self.sysfs_root / "class" / "vtconsole" / console / "bind").write_text("1")

    def unbind_pci(self, address: str) -> None:
        device = self.sysfs_root / "bus" / "pci" / "devices" / address
        driver = device / "driver"
        if driver.exists():
            (driver.resolve() / "unbind").write_text(address)

    def bind_pci(self, address: str, driver: str) -> None:
        device = self.sysfs_root / "bus" / "pci" / "devices" / address
        (device / "driver_override").write_text(driver)
        (self.sysfs_root / "bus" / "pci" / "drivers_probe").write_text(address)

    def release_pci(self, address: str) -> None:
        device = self.sysfs_root / "bus" / "pci" / "devices" / address
        driver = device / "driver"
        if driver.exists():
            (driver.resolve() / "unbind").write_text(address)
        (device / "driver_override").write_text("\n")

    def probe_pci(self, address: str) -> None:
        (self.sysfs_root / "bus" / "pci" / "drivers_probe").write_text(address)

    def reset_pci(self, address: str) -> None:
        (self.sysfs_root / "bus" / "pci" / "devices" / address / "reset").write_text(
            "1"
        )

    def start_domain(self, domain_name: str, xml_path: Path) -> None:
        self._run(["virsh", "define", str(xml_path)])
        self._run(["virsh", "start", domain_name])

    def wait_domain(self, domain_name: str) -> None:
        while True:
            state = self._run(
                ["virsh", "domstate", domain_name],
                check=False,
            )
            if state.returncode == 0 and state.stdout.strip().lower() in {
                "shut off",
                "crashed",
            }:
                return
            time.sleep(1)

    def _domain_state(self, domain_name: str) -> str:
        state = self._run(
            ["virsh", "domstate", domain_name],
            check=False,
        )
        if state.returncode == 0:
            return state.stdout.strip().lower()

        domains = self._run(
            ["virsh", "list", "--all", "--name"],
            check=False,
        )
        if domains.returncode == 0 and domain_name not in {
            name.strip() for name in domains.stdout.splitlines()
        }:
            raise DomainNotFoundError(f"domain {domain_name} does not exist")
        raise RuntimeError(
            state.stderr.strip()
            or domains.stderr.strip()
            or f"failed to determine whether domain {domain_name} is active"
        )

    def stop_domain(self, domain_name: str) -> None:
        terminal_states = {"shut off", "crashed"}
        state = self._domain_state(domain_name)
        if state in terminal_states:
            return

        stopped = self._run(["virsh", "destroy", domain_name], check=False)
        if stopped.returncode != 0:
            final_state = self._domain_state(domain_name)
            if final_state not in terminal_states:
                raise RuntimeError(
                    stopped.stderr.strip()
                    or f"failed to stop active domain {domain_name}"
                )
            return
        self.wait_domain(domain_name)

    def path_exists(self, path: Path) -> bool:
        return path.exists()

    def is_readable_file(self, path: Path) -> bool:
        return path.is_file() and os.access(path, os.R_OK)

    def create_sparse_disk(self, path: Path, size_gib: int) -> None:
        path.parent.mkdir(parents=True, exist_ok=True)
        self._run(["qemu-img", "create", "-f", "qcow2", str(path), f"{size_gib}G"])

    def copy_atomic(self, source: Path, destination: Path) -> None:
        destination.parent.mkdir(parents=True, exist_ok=True)
        file_descriptor, temporary_name = tempfile.mkstemp(
            dir=destination.parent,
            prefix=f".{destination.name}.",
        )
        temporary = Path(temporary_name)
        try:
            with os.fdopen(file_descriptor, "wb") as output, source.open("rb") as input_file:
                shutil.copyfileobj(input_file, output)
                output.flush()
                os.fsync(output.fileno())
            os.replace(temporary, destination)
        except BaseException:
            temporary.unlink(missing_ok=True)
            raise

    def write_marker(self, path: Path) -> None:
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text("install\n")

    def remove_file(self, path: Path) -> None:
        path.unlink(missing_ok=True)

    def domain_active(self, domain_name: str) -> bool:
        result = self._run(["virsh", "domstate", domain_name], check=False)
        if result.returncode != 0:
            return False
        return result.stdout.strip().lower() not in {"shut off", "crashed", "no state"}

    def live_domain_xml(self, domain_name: str) -> str:
        return self._run(["virsh", "dumpxml", domain_name]).stdout

    def attach_usb_device(
        self, domain_name: str, vendor_id: str, product_id: str
    ) -> None:
        device_xml = (
            "<hostdev mode='subsystem' type='usb' managed='yes'>"
            "<source>"
            f"<vendor id='0x{vendor_id}'/>"
            f"<product id='0x{product_id}'/>"
            "</source>"
            "</hostdev>"
        )
        with tempfile.NamedTemporaryFile("w", suffix=".xml") as xml_file:
            xml_file.write(device_xml)
            xml_file.flush()
            self._run(
                ["virsh", "attach-device", domain_name, xml_file.name, "--live"]
            )


class Controller:
    def __init__(self, config: Config, system: System) -> None:
        self.config = config
        self.system = system
        self._state_saved = False
        self._unbound_consoles: list[str] = []
        self._audio_unbound = False
        self._gpu_unbound = False
        self._vfio_bound: list[str] = []

    def _drm_owner_diagnostics(self) -> list[str]:
        diagnostics = []
        for node in self.system.drm_nodes(self.config.gpu):
            owners = self.system.drm_owners(node)
            if owners:
                diagnostics.append(
                    f"DRM node {node} for GPU {self.config.gpu} is in use by "
                    + ", ".join(owners)
                )
        return diagnostics

    def check(self) -> list[str]:
        diagnostics: list[str] = []
        for session in self.system.graphical_sessions(self.config.username):
            if session.session_type in {"wayland", "x11"} and session.state in {
                "active",
                "online",
            }:
                diagnostics.append(
                    f"active graphical session {session.session_id} for "
                    f"{self.config.username} ({session.session_type})"
                )

        graphical_processes = sorted(
            self.system.process_names(self.config.username) & GRAPHICAL_PROCESSES
        )
        if graphical_processes:
            diagnostics.append(
                f"graphical processes still running for {self.config.username}: "
                + ", ".join(graphical_processes)
            )

        gpu_driver = self.system.pci_driver(self.config.gpu)
        if gpu_driver != "amdgpu":
            diagnostics.append(
                f"GPU {self.config.gpu} must be bound to amdgpu "
                f"(found {gpu_driver or 'no driver'})"
            )
        audio_driver = self.system.pci_driver(self.config.audio)
        if audio_driver != "snd_hda_intel":
            diagnostics.append(
                f"audio {self.config.audio} must be bound to snd_hda_intel "
                f"(found {audio_driver or 'no driver'})"
            )

        diagnostics.extend(self._drm_owner_diagnostics())
        return diagnostics

    def run(self) -> None:
        diagnostics = self.check()
        if diagnostics:
            raise PreflightError(diagnostics)

        consoles = self.system.bound_consoles()
        mutated = False
        failure: BaseException | None = None
        domain_launch_attempted = False
        try:
            self.system.save_consoles(self.config.state_directory, consoles)
            self._state_saved = True
            mutated = True

            for console in consoles:
                self.system.unbind_console(console)
                self._unbound_consoles.append(console)

            race_diagnostics = self._drm_owner_diagnostics()
            if race_diagnostics:
                raise PreflightError(race_diagnostics)

            self.system.unbind_pci(self.config.audio)
            self._audio_unbound = True
            self.system.unbind_pci(self.config.gpu)
            self._gpu_unbound = True

            self._vfio_bound.append(self.config.gpu)
            self.system.bind_pci(self.config.gpu, "vfio-pci")
            self._vfio_bound.append(self.config.audio)
            self.system.bind_pci(self.config.audio, "vfio-pci")

            install_marker = self.config.state_directory / INSTALL_MARKER
            install_mode = self.system.path_exists(install_marker)
            xml_path = self.config.install_xml if install_mode else self.config.normal_xml
            domain_launch_attempted = True
            self.system.start_domain(self.config.domain_name, xml_path)
            if install_mode:
                self.system.remove_file(install_marker)
            self.system.wait_domain(self.config.domain_name)
        except BaseException as error:
            failure = error

        should_restore = mutated
        if (
            mutated
            and isinstance(failure, KeyboardInterrupt)
            and domain_launch_attempted
        ):
            try:
                self.system.stop_domain(self.config.domain_name)
            except DomainNotFoundError:
                pass
            except Exception as stop_error:
                should_restore = False
                failure.add_note(f"domain stop before restore failed: {stop_error}")

        if should_restore:
            try:
                self._restore()
            except Exception as restore_error:
                if failure is None:
                    raise
                failure.add_note(f"rollback also failed: {restore_error}")
        if failure is not None:
            raise failure

    def _restore(self) -> None:
        errors: list[Exception] = []
        linux_drivers_ready = True

        failed_releases = []
        for address in reversed(self._vfio_bound):
            try:
                self.system.release_pci(address)
            except Exception as error:
                errors.append(error)
                failed_releases.append(address)
        self._vfio_bound = list(reversed(failed_releases))
        pending_releases = set(self._vfio_bound)

        if self._gpu_unbound:
            try:
                self.system.reset_pci(self.config.gpu)
            except Exception as error:
                errors.append(error)
            try:
                self.system.probe_pci(self.config.gpu)
                driver = self.system.pci_driver(self.config.gpu)
                if driver != "amdgpu":
                    raise RuntimeError(
                        f"GPU {self.config.gpu} failed to bind to amdgpu after probe "
                        f"(found {driver or 'no driver'})"
                    )
            except Exception as error:
                errors.append(error)
                linux_drivers_ready = False
            else:
                self._gpu_unbound = self.config.gpu in pending_releases
        if self._audio_unbound:
            try:
                self.system.probe_pci(self.config.audio)
                driver = self.system.pci_driver(self.config.audio)
                if driver != "snd_hda_intel":
                    raise RuntimeError(
                        f"audio {self.config.audio} failed to bind to snd_hda_intel "
                        f"after probe (found {driver or 'no driver'})"
                    )
            except Exception as error:
                errors.append(error)
                linux_drivers_ready = False
            else:
                self._audio_unbound = self.config.audio in pending_releases

        if linux_drivers_ready:
            consoles = list(self._unbound_consoles)
            if self._state_saved:
                try:
                    consoles = self.system.load_consoles(self.config.state_directory)
                except Exception as error:
                    errors.append(error)
            unbound = set(self._unbound_consoles)
            failed_consoles = []
            for console in reversed(consoles):
                if console not in unbound:
                    continue
                try:
                    self.system.bind_console(console)
                except Exception as error:
                    errors.append(error)
                    failed_consoles.append(console)
            self._unbound_consoles = list(reversed(failed_consoles))

            if self._state_saved and not self._unbound_consoles:
                try:
                    self.system.clear_consoles(self.config.state_directory)
                except Exception as error:
                    errors.append(error)
                else:
                    self._state_saved = False

        if errors:
            details = "; ".join(str(error) for error in errors)
            raise RuntimeError(f"VFIO restore failed: {details}") from errors[0]

    def prepare_install(self, iso: Path) -> None:
        if not self.system.is_readable_file(iso):
            raise ValueError(f"ISO is not a readable file: {iso}")
        if not self.system.path_exists(self.config.disk_path):
            self.system.create_sparse_disk(
                self.config.disk_path,
                self.config.disk_size_gib,
            )
        self.system.copy_atomic(iso, self.config.install_iso_path)
        self.system.write_marker(self.config.state_directory / INSTALL_MARKER)

    def attach_usb(self, vendor_id: str, product_id: str) -> None:
        identity = (_normalize_usb_id(vendor_id), _normalize_usb_id(product_id))
        configured = {device.normalized() for device in self.config.usb_devices}
        if identity not in configured:
            return
        if not self.system.domain_active(self.config.domain_name):
            return
        if _domain_has_usb(self.system.live_domain_xml(self.config.domain_name), identity):
            return
        self.system.attach_usb_device(self.config.domain_name, *identity)


def _normalize_usb_id(value: str) -> str:
    normalized = value.strip().lower()
    return normalized[2:] if normalized.startswith("0x") else normalized


def _domain_has_usb(xml: str, identity: tuple[str, str]) -> bool:
    root = ET.fromstring(xml)
    for host_device in root.findall(".//hostdev[@type='usb']"):
        source = host_device.find("source")
        if source is None:
            continue
        vendor = source.find("vendor")
        product = source.find("product")
        if vendor is None or product is None:
            continue
        actual = (
            _normalize_usb_id(vendor.get("id", "")),
            _normalize_usb_id(product.get("id", "")),
        )
        if actual == identity:
            return True
    return False


def _extract_option(arguments: list[str], option: str) -> str | None:
    if option not in arguments:
        return None
    index = arguments.index(option)
    if index + 1 == len(arguments):
        raise ValueError(f"{option} requires a value")
    value = arguments[index + 1]
    del arguments[index : index + 2]
    return value


def main(argv: Sequence[str]) -> int:
    arguments = list(argv)
    try:
        config_value = _extract_option(arguments, "--config")
    except ValueError as error:
        print(f"error: {error}", file=sys.stderr)
        return 2
    if config_value is None:
        print("error: --config is required", file=sys.stderr)
        return 2
    if not arguments:
        print("error: a subcommand is required", file=sys.stderr)
        return 2

    command = arguments.pop(0)
    known_commands = {"check", "run", "prepare-install", "attach-usb"}
    if command not in known_commands:
        print(f"error: unknown subcommand: {command}", file=sys.stderr)
        return 2

    iso_value: str | None = None
    if command == "prepare-install":
        try:
            iso_value = _extract_option(arguments, "--iso")
        except ValueError as error:
            print(f"error: {error}", file=sys.stderr)
            return 2
        if iso_value is None:
            print("error: prepare-install requires --iso", file=sys.stderr)
            return 2
    elif "--iso" in arguments:
        print(f"error: {command} does not accept --iso", file=sys.stderr)
        return 2

    if command == "attach-usb" and len(arguments) != 2:
        print("error: attach-usb requires VENDOR_ID PRODUCT_ID", file=sys.stderr)
        return 2
    if command != "attach-usb" and arguments:
        print(f"error: unexpected arguments for {command}: {' '.join(arguments)}", file=sys.stderr)
        return 2

    try:
        config = Config.from_json(Path(config_value))
        controller = Controller(config, RealSystem())
        if command == "check":
            diagnostics = controller.check()
            for diagnostic in diagnostics:
                print(diagnostic, file=sys.stderr)
            return 1 if diagnostics else 0
        if command == "run":
            controller.run()
        elif command == "prepare-install":
            if iso_value is None:
                raise AssertionError("prepare-install ISO was not parsed")
            controller.prepare_install(Path(iso_value))
        else:
            controller.attach_usb(arguments[0], arguments[1])
        return 0
    except PreflightError as error:
        for diagnostic in error.diagnostics:
            print(diagnostic, file=sys.stderr)
        return 1
    except (OSError, RuntimeError, ValueError, KeyError, json.JSONDecodeError) as error:
        print(f"error: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
