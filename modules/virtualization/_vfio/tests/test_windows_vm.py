from __future__ import annotations

import io
import json
import subprocess
import tempfile
import unittest
from contextlib import redirect_stderr
from pathlib import Path
from unittest.mock import patch

from modules.virtualization._vfio.windows_vm import (
    Config,
    Controller,
    PreflightError,
    RealSystem,
    Session,
    System,
    UsbDevice,
    main,
)


GPU = "0000:2f:00.0"
AUDIO = "0000:2f:00.1"


class FakeSystem(System):
    def __init__(self, root: Path) -> None:
        super().__init__(sysfs_root=root / "sys", dev_root=root / "dev")
        self.sessions: list[Session] = []
        self.processes: set[str] = set()
        self.drivers = {GPU: "amdgpu", AUDIO: "snd_hda_intel"}
        self.owners: dict[Path, tuple[str, ...]] = {}
        self.consoles = ["vtcon0"]
        self.operations: list[str] = []
        self.files: set[Path] = set()
        self.readable: set[Path] = set()
        self.saved_consoles: tuple[str, ...] = ()
        self.domain_is_active = True
        self.domain_xml = "<domain><devices /></domain>"
        self.fail_start = False
        self.fail_wait = False
        self.interrupt_wait = False
        self.fail_stop = False
        self.fail_bind_addresses: set[str] = set()
        self.fail_bind_before_mutation_addresses: set[str] = set()
        self.fail_release_addresses: set[str] = set()
        self.interrupt_bind_addresses: set[str] = set()
        self.unbound_probe_addresses: set[str] = set()
        self.owner_responses: list[dict[Path, tuple[str, ...]]] = []

    def graphical_sessions(self, username: str) -> list[Session]:
        return [session for session in self.sessions if session.username == username]

    def process_names(self, username: str) -> set[str]:
        return set(self.processes)

    def pci_driver(self, address: str) -> str | None:
        return self.drivers.get(address)

    def drm_owners(self, node: Path) -> tuple[str, ...]:
        if self.owner_responses:
            return self.owner_responses.pop(0).get(node, ())
        return self.owners.get(node, ())

    def bound_consoles(self) -> list[str]:
        return list(self.consoles)

    def save_consoles(self, state_directory: Path, consoles: list[str]) -> None:
        self.saved_consoles = tuple(consoles)

    def load_consoles(self, state_directory: Path) -> list[str]:
        return list(self.saved_consoles)

    def clear_consoles(self, state_directory: Path) -> None:
        self.saved_consoles = ()

    def unbind_console(self, console: str) -> None:
        self.operations.append(f"console:unbind:{console}")

    def bind_console(self, console: str) -> None:
        self.operations.append(f"console:bind:{console}")

    def unbind_pci(self, address: str) -> None:
        self.operations.append(f"pci:unbind:{address}")
        self.drivers[address] = None

    def bind_pci(self, address: str, driver: str) -> None:
        if address in self.fail_bind_before_mutation_addresses:
            raise RuntimeError(f"driver_override write failed for {address}")
        self.operations.append(f"pci:bind:{driver}:{address}")
        if address in self.interrupt_bind_addresses:
            raise KeyboardInterrupt
        if address in self.fail_bind_addresses:
            raise RuntimeError(f"VFIO probe failed for {address}")
        self.drivers[address] = driver

    def release_pci(self, address: str) -> None:
        self.operations.append(f"pci:release:{address}")
        if address in self.fail_release_addresses:
            raise RuntimeError(f"driver_override clear failed for {address}")
        self.drivers[address] = None

    def probe_pci(self, address: str) -> None:
        self.operations.append(f"pci:probe:{address}")
        if address in self.unbound_probe_addresses:
            self.drivers[address] = None
            return
        self.drivers[address] = "amdgpu" if address == GPU else "snd_hda_intel"

    def reset_pci(self, address: str) -> None:
        self.operations.append(f"pci:reset:{address}")

    def start_domain(self, domain_name: str, xml_path: Path) -> None:
        self.operations.append(f"vm:start:{domain_name}:{xml_path.name}")
        if self.fail_start:
            raise RuntimeError("qemu failed to start")

    def wait_domain(self, domain_name: str) -> None:
        self.operations.append(f"vm:wait:{domain_name}")
        if self.fail_wait:
            raise RuntimeError("domain crashed")
        if self.interrupt_wait:
            raise KeyboardInterrupt

    def stop_domain(self, domain_name: str) -> None:
        self.operations.append(f"vm:stop:{domain_name}")
        if self.fail_stop:
            raise RuntimeError("failed to stop domain")
        self.domain_is_active = False

    def path_exists(self, path: Path) -> bool:
        return path in self.files

    def is_readable_file(self, path: Path) -> bool:
        return path in self.files and path in self.readable

    def create_sparse_disk(self, path: Path, size_gib: int) -> None:
        self.operations.append(f"disk:create:{path}:{size_gib}G")
        self.files.add(path)

    def copy_atomic(self, source: Path, destination: Path) -> None:
        self.operations.append(f"copy:{source}:{destination}")
        self.files.add(destination)

    def write_marker(self, path: Path) -> None:
        self.operations.append(f"marker:write:{path}")
        self.files.add(path)

    def remove_file(self, path: Path) -> None:
        self.files.discard(path)

    def domain_active(self, domain_name: str) -> bool:
        return self.domain_is_active

    def live_domain_xml(self, domain_name: str) -> str:
        return self.domain_xml

    def attach_usb_device(
        self, domain_name: str, vendor_id: str, product_id: str
    ) -> None:
        self.operations.append(
            f"usb:attach:{domain_name}:{vendor_id.lower()}:{product_id.lower()}"
        )
        self.domain_xml = (
            "<domain><devices><hostdev type='usb'><source>"
            f"<vendor id='0x{vendor_id.lower()}'/>"
            f"<product id='0x{product_id.lower()}'/>"
            "</source></hostdev></devices></domain>"
        )


def make_config(root: Path, usb_devices: tuple[UsbDevice, ...] = ()) -> Config:
    return Config(
        domain_name="windows",
        username="dusty",
        gpu=GPU,
        audio=AUDIO,
        usb_devices=usb_devices,
        disk_path=root / "windows.qcow2",
        disk_size_gib=500,
        normal_xml=root / "windows.xml",
        install_xml=root / "windows-install.xml",
        install_iso_path=root / "installer.iso",
        state_directory=root / "state",
    )


def add_drm_node(system: FakeSystem, address: str, name: str) -> Path:
    device = system.sysfs_root / "bus" / "pci" / "devices" / address
    drm_node = device / "drm" / name
    drm_node.mkdir(parents=True)
    (drm_node / "device").symlink_to("../..")
    dev_node = system.dev_root / "dri" / name
    dev_node.parent.mkdir(parents=True, exist_ok=True)
    dev_node.touch()
    return dev_node


class ConfigTests(unittest.TestCase):
    def test_from_json_parses_contract(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_directory:
            root = Path(temporary_directory)
            config_path = root / "config.json"
            config_path.write_text(
                json.dumps(
                    {
                        "domainName": "windows",
                        "username": "dusty",
                        "gpu": GPU,
                        "audio": AUDIO,
                        "usbDevices": [
                            {"vendorId": "046d", "productId": "c547"}
                        ],
                        "diskPath": str(root / "windows.qcow2"),
                        "diskSizeGiB": 500,
                        "normalXml": str(root / "windows.xml"),
                        "installXml": str(root / "windows-install.xml"),
                        "installIsoPath": str(root / "installer.iso"),
                        "stateDirectory": str(root / "state"),
                    }
                )
            )

            config = Config.from_json(config_path)

            self.assertEqual(config.domain_name, "windows")
            self.assertEqual(config.usb_devices, (UsbDevice("046d", "c547"),))
            self.assertEqual(config.disk_size_gib, 500)
            self.assertEqual(config.state_directory, root / "state")


class ControllerTestCase(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary_directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary_directory.cleanup)
        self.root = Path(self.temporary_directory.name)
        self.system = FakeSystem(self.root)
        self.config = make_config(self.root)
        self.gpu_node = add_drm_node(self.system, GPU, "card7")
        self.controller = Controller(self.config, self.system)


class PreflightTests(ControllerTestCase):
    def test_check_reports_active_graphical_session(self) -> None:
        self.system.sessions = [Session("3", "dusty", "wayland", "active")]
        self.system.processes = {"Hyprland", "Xwayland", "fish"}

        self.assertEqual(
            self.controller.check(),
            [
                "active graphical session 3 for dusty (wayland)",
                "graphical processes still running for dusty: Hyprland, Xwayland",
            ],
        )

    def test_check_reports_drm_owner_by_pci_device(self) -> None:
        self.system.owners[self.gpu_node] = ("Hyprland[1402]",)

        self.assertEqual(
            self.controller.check(),
            [
                f"DRM node {self.gpu_node} for GPU {GPU} is in use by Hyprland[1402]"
            ],
        )

    def test_check_accepts_changed_drm_node_number(self) -> None:
        old_node = self.gpu_node
        old_node.unlink()
        (self.system.sysfs_root / "bus" / "pci" / "devices" / GPU / "drm" / "card7" / "device").unlink()
        new_node = add_drm_node(self.system, GPU, "card42")
        self.system.owners[new_node] = ()

        self.assertEqual(self.controller.check(), [])

    def test_check_reports_wrong_gpu_driver(self) -> None:
        self.system.drivers[GPU] = "vfio-pci"

        self.assertEqual(
            self.controller.check(),
            [f"GPU {GPU} must be bound to amdgpu (found vfio-pci)"],
        )

    def test_failed_check_performs_no_mutation(self) -> None:
        self.system.sessions = [Session("3", "dusty", "wayland", "active")]

        with self.assertRaises(PreflightError):
            self.controller.run()

        self.assertEqual(self.system.operations, [])
        self.assertEqual(self.system.saved_consoles, ())


class LifecycleTests(ControllerTestCase):
    expected_handoff = [
        "console:unbind:vtcon0",
        f"pci:unbind:{AUDIO}",
        f"pci:unbind:{GPU}",
        f"pci:bind:vfio-pci:{GPU}",
        f"pci:bind:vfio-pci:{AUDIO}",
        "vm:start:windows:windows.xml",
        "vm:wait:windows",
        f"pci:release:{AUDIO}",
        f"pci:release:{GPU}",
        f"pci:reset:{GPU}",
        f"pci:probe:{GPU}",
        f"pci:probe:{AUDIO}",
        "console:bind:vtcon0",
    ]

    def test_run_hands_off_in_order(self) -> None:
        self.controller.run()

        self.assertEqual(self.system.operations, self.expected_handoff)

    def test_qemu_start_failure_restores_in_reverse_order(self) -> None:
        self.system.fail_start = True

        with self.assertRaisesRegex(RuntimeError, "qemu failed to start"):
            self.controller.run()

        self.assertEqual(
            self.system.operations,
            [operation for operation in self.expected_handoff if operation != "vm:wait:windows"],
        )

    def test_partial_vfio_bind_failure_clears_override(self) -> None:
        self.system.fail_bind_addresses.add(GPU)

        with self.assertRaisesRegex(RuntimeError, "VFIO probe failed"):
            self.controller.run()

        self.assertEqual(
            self.system.operations,
            [
                "console:unbind:vtcon0",
                f"pci:unbind:{AUDIO}",
                f"pci:unbind:{GPU}",
                f"pci:bind:vfio-pci:{GPU}",
                f"pci:release:{GPU}",
                f"pci:reset:{GPU}",
                f"pci:probe:{GPU}",
                f"pci:probe:{AUDIO}",
                "console:bind:vtcon0",
            ],
        )

    def test_bind_override_failure_still_reprobes_and_restores_console(self) -> None:
        self.system.fail_bind_before_mutation_addresses.add(GPU)
        self.system.fail_release_addresses.add(GPU)

        with self.assertRaisesRegex(RuntimeError, "driver_override write failed"):
            self.controller.run()

        self.assertEqual(
            self.system.operations,
            [
                "console:unbind:vtcon0",
                f"pci:unbind:{AUDIO}",
                f"pci:unbind:{GPU}",
                f"pci:release:{GPU}",
                f"pci:reset:{GPU}",
                f"pci:probe:{GPU}",
                f"pci:probe:{AUDIO}",
                "console:bind:vtcon0",
            ],
        )

    def test_restore_retry_reprobes_after_retained_release(self) -> None:
        self.system.fail_bind_before_mutation_addresses.add(GPU)
        self.system.fail_release_addresses.add(GPU)

        with self.assertRaisesRegex(RuntimeError, "driver_override write failed"):
            self.controller.run()

        self.system.fail_release_addresses.clear()
        self.controller._restore()

        self.assertEqual(self.system.drivers[GPU], "amdgpu")
        self.assertEqual(self.system.drivers[AUDIO], "snd_hda_intel")
        self.assertEqual(
            self.system.operations[-3:],
            [
                f"pci:release:{GPU}",
                f"pci:reset:{GPU}",
                f"pci:probe:{GPU}",
            ],
        )

    def test_restore_is_idempotent(self) -> None:
        self.controller.run()
        operations_after_run = list(self.system.operations)

        self.controller._restore()

        self.assertEqual(self.system.operations, operations_after_run)

    def test_vm_crash_runs_restore(self) -> None:
        self.system.fail_wait = True

        with self.assertRaisesRegex(RuntimeError, "domain crashed"):
            self.controller.run()

        self.assertEqual(self.system.operations, self.expected_handoff)

    def test_interrupt_before_domain_launch_restores_host_directly(self) -> None:
        self.system.interrupt_bind_addresses.add(GPU)
        self.system.fail_stop = True

        with self.assertRaises(KeyboardInterrupt):
            self.controller.run()

        self.assertEqual(
            self.system.operations,
            [
                "console:unbind:vtcon0",
                f"pci:unbind:{AUDIO}",
                f"pci:unbind:{GPU}",
                f"pci:bind:vfio-pci:{GPU}",
                f"pci:release:{GPU}",
                f"pci:reset:{GPU}",
                f"pci:probe:{GPU}",
                f"pci:probe:{AUDIO}",
                "console:bind:vtcon0",
            ],
        )
        self.assertEqual(self.system.drivers[GPU], "amdgpu")
        self.assertEqual(self.system.drivers[AUDIO], "snd_hda_intel")
        self.assertEqual(self.system.saved_consoles, ())

    def test_interrupt_stops_domain_before_restoring_gpu(self) -> None:
        self.system.interrupt_wait = True

        with self.assertRaises(KeyboardInterrupt):
            self.controller.run()

        self.assertEqual(
            self.system.operations,
            self.expected_handoff[:7]
            + ["vm:stop:windows"]
            + self.expected_handoff[7:],
        )
        self.assertFalse(self.system.domain_is_active)

    def test_interrupt_stop_failure_keeps_gpu_on_vfio(self) -> None:
        self.system.interrupt_wait = True
        self.system.fail_stop = True

        with self.assertRaises(KeyboardInterrupt) as raised:
            self.controller.run()

        self.assertEqual(
            self.system.operations,
            self.expected_handoff[:7] + ["vm:stop:windows"],
        )
        self.assertEqual(self.system.drivers[GPU], "vfio-pci")
        self.assertEqual(self.system.drivers[AUDIO], "vfio-pci")
        self.assertIn(
            "domain stop before restore failed: failed to stop domain",
            raised.exception.__notes__,
        )

    def test_restore_rejects_missing_gpu_driver_and_defers_consoles(self) -> None:
        self.system.unbound_probe_addresses.add(GPU)

        with self.assertRaisesRegex(
            RuntimeError,
            rf"GPU {GPU} failed to bind to amdgpu after probe \(found no driver\)",
        ):
            self.controller.run()

        self.assertNotIn("console:bind:vtcon0", self.system.operations)
        self.assertEqual(self.system.saved_consoles, ("vtcon0",))

        self.system.unbound_probe_addresses.clear()
        self.controller._restore()

        self.assertEqual(self.system.drivers[GPU], "amdgpu")
        self.assertEqual(
            self.system.operations[-3:],
            [
                f"pci:reset:{GPU}",
                f"pci:probe:{GPU}",
                "console:bind:vtcon0",
            ],
        )
        self.assertEqual(self.system.saved_consoles, ())

    def test_restore_rejects_missing_audio_driver_and_defers_consoles(self) -> None:
        self.system.unbound_probe_addresses.add(AUDIO)

        with self.assertRaisesRegex(
            RuntimeError,
            rf"audio {AUDIO} failed to bind to snd_hda_intel after probe "
            r"\(found no driver\)",
        ):
            self.controller.run()

        self.assertNotIn("console:bind:vtcon0", self.system.operations)
        self.assertEqual(self.system.saved_consoles, ("vtcon0",))

        self.system.unbound_probe_addresses.clear()
        self.controller._restore()

        self.assertEqual(self.system.drivers[AUDIO], "snd_hda_intel")
        self.assertEqual(
            self.system.operations[-2:],
            [f"pci:probe:{AUDIO}", "console:bind:vtcon0"],
        )
        self.assertEqual(self.system.saved_consoles, ())

    def test_drm_race_restores_linux_ownership(self) -> None:
        self.system.owner_responses = [
            {self.gpu_node: ()},
            {self.gpu_node: ("Hyprland[2301]",)},
        ]

        with self.assertRaises(PreflightError):
            self.controller.run()

        self.assertEqual(
            self.system.operations,
            ["console:unbind:vtcon0", "console:bind:vtcon0"],
        )
        self.assertEqual(self.system.saved_consoles, ())


class RealSystemTests(unittest.TestCase):
    def test_wait_domain_retries_failed_status_queries_until_stopped(self) -> None:
        system = RealSystem()
        responses = [
            subprocess.CompletedProcess([], 1, "", "libvirt connection reset"),
            subprocess.CompletedProcess([], 0, "running\n", ""),
            subprocess.CompletedProcess([], 0, "shut off\n", ""),
        ]

        with (
            patch.object(system, "_run", side_effect=responses) as run,
            patch("modules.virtualization._vfio.windows_vm.time.sleep") as sleep,
        ):
            system.wait_domain("windows")

        self.assertEqual(run.call_count, 3)
        self.assertEqual(sleep.call_count, 2)


class InstallTests(ControllerTestCase):
    def setUp(self) -> None:
        super().setUp()
        self.iso = self.root / "source.iso"
        self.system.files.add(self.iso)
        self.system.readable.add(self.iso)

    def test_prepare_install_creates_sparse_disk_once(self) -> None:
        self.controller.prepare_install(self.iso)
        self.controller.prepare_install(self.iso)

        create_operation = f"disk:create:{self.config.disk_path}:500G"
        self.assertEqual(self.system.operations.count(create_operation), 1)
        self.assertIn(self.config.install_iso_path, self.system.files)
        self.assertIn(self.config.state_directory / "install-mode", self.system.files)

    def test_prepare_install_preserves_existing_disk_and_nvram(self) -> None:
        nvram = self.root / "windows_VARS.fd"
        self.system.files.update({self.config.disk_path, nvram})

        self.controller.prepare_install(self.iso)

        self.assertIn(self.config.disk_path, self.system.files)
        self.assertIn(nvram, self.system.files)
        self.assertNotIn(
            f"disk:create:{self.config.disk_path}:500G", self.system.operations
        )

    def test_prepare_install_rejects_unreadable_iso(self) -> None:
        self.system.readable.clear()

        with self.assertRaisesRegex(ValueError, "ISO is not a readable file"):
            self.controller.prepare_install(self.iso)

        self.assertEqual(self.system.operations, [])


class UsbTests(ControllerTestCase):
    def setUp(self) -> None:
        super().setUp()
        self.config = make_config(
            self.root,
            usb_devices=(UsbDevice("046d", "c547"),),
        )
        self.controller = Controller(self.config, self.system)

    def test_missing_usb_device_does_not_block_run(self) -> None:
        self.controller.run()

        self.assertEqual(self.system.operations, LifecycleTests.expected_handoff)

    def test_attach_usb_ignores_unconfigured_identity(self) -> None:
        self.controller.attach_usb("1234", "abcd")

        self.assertEqual(self.system.operations, [])

    def test_attach_usb_ignores_inactive_domain(self) -> None:
        self.system.domain_is_active = False

        self.controller.attach_usb("046d", "c547")

        self.assertEqual(self.system.operations, [])

    def test_attach_usb_is_idempotent_after_kvm_reconnect(self) -> None:
        self.controller.attach_usb("046D", "C547")
        self.controller.attach_usb("046d", "c547")

        self.assertEqual(
            self.system.operations,
            ["usb:attach:windows:046d:c547"],
        )


class CliTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary_directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary_directory.cleanup)
        self.root = Path(self.temporary_directory.name)
        self.config = make_config(self.root)
        self.config_path = self.root / "config.json"
        self.config_path.write_text(
            json.dumps(
                {
                    "domainName": self.config.domain_name,
                    "username": self.config.username,
                    "gpu": self.config.gpu,
                    "audio": self.config.audio,
                    "usbDevices": [],
                    "diskPath": str(self.config.disk_path),
                    "diskSizeGiB": self.config.disk_size_gib,
                    "normalXml": str(self.config.normal_xml),
                    "installXml": str(self.config.install_xml),
                    "installIsoPath": str(self.config.install_iso_path),
                    "stateDirectory": str(self.config.state_directory),
                }
            )
        )
        self.system = FakeSystem(self.root)
        add_drm_node(self.system, GPU, "card7")

    def test_check_exit_codes(self) -> None:
        with patch(
            "modules.virtualization._vfio.windows_vm.RealSystem",
            return_value=self.system,
        ):
            self.assertEqual(main(["--config", str(self.config_path), "check"]), 0)
            self.system.sessions = [Session("3", "dusty", "wayland", "active")]
            stderr = io.StringIO()
            with redirect_stderr(stderr):
                self.assertEqual(
                    main(["--config", str(self.config_path), "check"]), 1
                )

        self.assertIn("active graphical session 3", stderr.getvalue())

    def test_prepare_install_requires_iso(self) -> None:
        stderr = io.StringIO()

        with redirect_stderr(stderr):
            exit_code = main(
                ["--config", str(self.config_path), "prepare-install"]
            )

        self.assertEqual(exit_code, 2)
        self.assertIn("prepare-install requires --iso", stderr.getvalue())

    def test_unknown_subcommand_fails(self) -> None:
        stderr = io.StringIO()

        with redirect_stderr(stderr):
            exit_code = main(["--config", str(self.config_path), "launch"])

        self.assertEqual(exit_code, 2)
        self.assertIn("unknown subcommand: launch", stderr.getvalue())


if __name__ == "__main__":
    unittest.main()
