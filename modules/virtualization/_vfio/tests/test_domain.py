import re
import subprocess
import tempfile
import unittest
import xml.etree.ElementTree as ET
from pathlib import Path


TEMPLATE_DIRECTORY = Path(__file__).resolve().parents[1]
PLACEHOLDER_PATTERN = re.compile(r"@[A-Za-z][A-Za-z0-9]*@")
SUBSTITUTIONS = {
    "domainName": "windows-vm",
    "memoryMiB": "32768",
    "vcpus": "16",
    "diskPath": "/var/lib/libvirt/images/windows-vm.qcow2",
    "ovmfCode": "/run/libvirt/nix-ovmf/OVMF_CODE.secboot.fd",
    "ovmfVars": "/var/lib/libvirt/qemu/nvram/windows-vm_VARS.fd",
    "virtioIso": "/run/current-system/sw/share/virtio-win/virtio-win.iso",
    "windowsIso": "/var/lib/libvirt/images/windows-vm-install.iso",
    "gpuDomain": "0000",
    "gpuBus": "2f",
    "gpuSlot": "00",
    "gpuFunction": "0",
    "audioDomain": "0000",
    "audioBus": "2f",
    "audioSlot": "00",
    "audioFunction": "1",
    "usb1Vendor": "045e",
    "usb1Product": "02fe",
    "usb2Vendor": "3344",
    "usb2Product": "8384",
    "usb3Vendor": "3344",
    "usb3Product": "4384",
    "usb4Vendor": "3297",
    "usb4Product": "1969",
    "usb5Vendor": "1532",
    "usb5Product": "00a8",
}


def render_template(template_name: str, destination: Path) -> None:
    template = (TEMPLATE_DIRECTORY / template_name).read_text()
    placeholders = set(PLACEHOLDER_PATTERN.findall(template))
    expected = {f"@{name}@" for name in SUBSTITUTIONS}
    unknown = placeholders - expected
    if unknown:
        raise AssertionError(f"unknown substitution tokens in {template_name}: {sorted(unknown)}")

    rendered = template
    for name, value in SUBSTITUTIONS.items():
        rendered = rendered.replace(f"@{name}@", value)

    remaining = PLACEHOLDER_PATTERN.findall(rendered)
    if remaining:
        raise AssertionError(
            f"unrendered substitution tokens in {template_name}: {remaining}"
        )
    destination.write_text(rendered)


class DomainTemplateTests(unittest.TestCase):
    def setUp(self) -> None:
        temporary_directory = tempfile.TemporaryDirectory()
        self.addCleanup(temporary_directory.cleanup)
        self.directory = Path(temporary_directory.name)
        self.normal_path = self.directory / "domain.xml"
        self.install_path = self.directory / "domain-install.xml"
        render_template("domain.xml.in", self.normal_path)
        render_template("domain-install.xml.in", self.install_path)
        self.normal = ET.parse(self.normal_path).getroot()
        self.install = ET.parse(self.install_path).getroot()

    def test_normal_domain_contract(self) -> None:
        root = self.normal
        self.assertEqual(root.tag, "domain")
        self.assertEqual(root.get("type"), "kvm")
        self.assertEqual(root.findtext("name"), "windows-vm")

        memory = root.find("memory")
        self.assertIsNotNone(memory)
        self.assertEqual(memory.get("unit"), "MiB")
        self.assertEqual(memory.text, "32768")
        self.assertEqual(root.findtext("vcpu"), "16")

        os_type = root.find("./os/type")
        self.assertIsNotNone(os_type)
        self.assertEqual(os_type.get("arch"), "x86_64")
        self.assertEqual(os_type.get("machine"), "q35")

        cpu = root.find("cpu")
        self.assertIsNotNone(cpu)
        self.assertEqual(cpu.get("mode"), "host-passthrough")

        loader = root.find("./os/loader")
        self.assertIsNotNone(loader)
        self.assertEqual(loader.get("type"), "pflash")
        self.assertEqual(loader.get("readonly"), "yes")
        self.assertEqual(loader.get("secure"), "yes")
        self.assertEqual(loader.text, SUBSTITUTIONS["ovmfCode"])
        self.assertEqual(root.findtext("./os/nvram"), SUBSTITUTIONS["ovmfVars"])

        tpm = root.find("./devices/tpm")
        self.assertIsNotNone(tpm)
        self.assertEqual(tpm.get("model"), "tpm-crb")
        tpm_backend = tpm.find("backend")
        self.assertIsNotNone(tpm_backend)
        self.assertEqual(tpm_backend.get("type"), "emulator")
        self.assertEqual(tpm_backend.get("version"), "2.0")

        system_disk = root.find("./devices/disk[@device='disk']")
        self.assertIsNotNone(system_disk)
        self.assertEqual(system_disk.get("type"), "file")
        driver = system_disk.find("driver")
        self.assertIsNotNone(driver)
        self.assertEqual(driver.get("type"), "qcow2")
        self.assertEqual(driver.get("discard"), "unmap")
        self.assertEqual(
            system_disk.find("source").get("file"), SUBSTITUTIONS["diskPath"]
        )
        target = system_disk.find("target")
        self.assertIsNotNone(target)
        self.assertEqual(target.get("bus"), "scsi")
        self.assertIsNotNone(
            root.find("./devices/controller[@type='scsi'][@model='virtio-scsi']")
        )

        interface = root.find("./devices/interface")
        self.assertIsNotNone(interface)
        self.assertEqual(interface.get("type"), "user")
        self.assertEqual(interface.find("model").get("type"), "virtio")

        pci_devices = root.findall("./devices/hostdev[@type='pci']")
        self.assertEqual(len(pci_devices), 2)
        addresses = {
            tuple(source.find("address").get(field) for field in ("domain", "bus", "slot", "function"))
            for source in (device.find("source") for device in pci_devices)
        }
        self.assertEqual(
            addresses,
            {
                ("0x0000", "0x2f", "0x00", "0x0"),
                ("0x0000", "0x2f", "0x00", "0x1"),
            },
        )
        graphics_device = next(
            device
            for device in pci_devices
            if device.find("source/address").get("function") == "0x0"
        )
        self.assertEqual(graphics_device.get("display"), "on")
        self.assertIsNotNone(root.find("./devices/video/model[@type='none']"))
        self.assertIsNotNone(root.find("./devices/serial"))
        self.assertIsNotNone(root.find("./devices/console"))
        self.assertIsNone(root.find("./devices/graphics"))

    def test_install_domain_adds_two_cdroms(self) -> None:
        self.assertEqual(self.normal.findall("./devices/disk[@device='cdrom']"), [])
        cdroms = self.install.findall("./devices/disk[@device='cdrom']")
        self.assertEqual(len(cdroms), 2)
        self.assertEqual(
            {cdrom.find("source").get("file") for cdrom in cdroms},
            {SUBSTITUTIONS["windowsIso"], SUBSTITUTIONS["virtioIso"]},
        )
        for cdrom in cdroms:
            self.assertEqual(cdrom.get("type"), "file")
            self.assertIsNotNone(cdrom.find("readonly"))
            self.assertEqual(cdrom.find("target").get("bus"), "sata")
        self.assertEqual(
            self.normal.findtext("./os/nvram"), self.install.findtext("./os/nvram")
        )

        self.assertEqual(self.install.findtext("memory"), "32768")
        self.assertEqual(self.install.findtext("vcpu"), "16")
        self.assertEqual(self.install.find("./os/type").get("machine"), "q35")
        self.assertEqual(self.install.find("cpu").get("mode"), "host-passthrough")
        install_loader = self.install.find("./os/loader")
        self.assertEqual(install_loader.get("readonly"), "yes")
        self.assertEqual(install_loader.get("secure"), "yes")
        self.assertEqual(
            self.install.find("./devices/tpm/backend").get("version"), "2.0"
        )
        install_disk = self.install.find("./devices/disk[@device='disk']")
        self.assertEqual(install_disk.find("driver").get("discard"), "unmap")
        self.assertEqual(install_disk.find("target").get("bus"), "scsi")
        self.assertEqual(
            self.install.find("./devices/interface").get("type"), "user"
        )
        self.assertEqual(
            self.install.find("./devices/interface/model").get("type"), "virtio"
        )
        install_pci_devices = self.install.findall(
            "./devices/hostdev[@type='pci']"
        )
        self.assertEqual(len(install_pci_devices), 2)
        self.assertEqual(install_pci_devices[0].get("display"), "on")
        self.assertIsNone(self.install.find("./devices/graphics"))

    def test_usb_devices_are_optional(self) -> None:
        expected_identities = {
            ("0x045e", "0x02fe"),
            ("0x3344", "0x8384"),
            ("0x3344", "0x4384"),
            ("0x3297", "0x1969"),
            ("0x1532", "0x00a8"),
        }
        for root in (self.normal, self.install):
            usb_devices = root.findall("./devices/hostdev[@type='usb']")
            self.assertEqual(len(usb_devices), 5)
            identities = set()
            for device in usb_devices:
                source = device.find("source")
                self.assertIsNotNone(source)
                self.assertEqual(source.get("startupPolicy"), "optional")
                identities.add(
                    (source.find("vendor").get("id"), source.find("product").get("id"))
                )
            self.assertEqual(identities, expected_identities)

    def test_domain_does_not_expose_host_storage(self) -> None:
        for root, allowed_files in (
            (self.normal, {SUBSTITUTIONS["diskPath"]}),
            (
                self.install,
                {
                    SUBSTITUTIONS["diskPath"],
                    SUBSTITUTIONS["windowsIso"],
                    SUBSTITUTIONS["virtioIso"],
                },
            ),
        ):
            self.assertEqual(root.findall("./devices/filesystem"), [])
            self.assertEqual(root.findall("./devices/disk[@type='block']"), [])
            self.assertEqual(root.findall("./devices/disk/source[@dev]"), [])
            exposed_files = {
                source.get("file")
                for source in root.findall("./devices/disk/source[@file]")
            }
            self.assertEqual(exposed_files, allowed_files)

    def test_rendered_domains_pass_virt_xml_validate(self) -> None:
        for path in (self.normal_path, self.install_path):
            result = subprocess.run(
                ["virt-xml-validate", str(path)],
                capture_output=True,
                text=True,
                check=False,
            )
            self.assertEqual(
                result.returncode,
                0,
                msg=f"{path.name} failed validation:\n{result.stdout}{result.stderr}",
            )


if __name__ == "__main__":
    unittest.main()
