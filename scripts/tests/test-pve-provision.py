"""Regression for re-provisioning a CT on a recycled DHCP address."""

import importlib.util
import io
import os
from pathlib import Path
import socket
import tempfile
import unittest
from contextlib import redirect_stdout
from unittest.mock import patch

MODULE = Path(__file__).resolve().parents[2] / "pkgs/pve-provision.py"
spec = importlib.util.spec_from_file_location("pve_provision", MODULE)
provision = importlib.util.module_from_spec(spec)
spec.loader.exec_module(provision)


class FakePve:
    def request(self, method, path, params=None):
        return "task-id"

    def wait_task(self, node, upid, label):
        pass


class ProvisionTests(unittest.TestCase):
    def test_recycled_address_does_not_block_identity_install(self):
        """The CT gets its identity despite a previous occupant's SSH host key."""
        args = provision.parse_args([
            "--url", "https://pve.example:8006", "lxc", "ishar", "--node", "roshar",
            "--template", "local:vztmpl/ishar.tar.xz", "--age-key-file", "key.txt",
        ])
        identity = b"# age identity\nAGE-SECRET-KEY-TEST\n"
        installed = []
        used_hosts_files = []

        def ssh_run(argv, **kwargs):
            self.assertEqual(argv[0], "ssh")
            hosts_files = [arg.split("=", 1)[1] for arg in argv if arg.startswith("UserKnownHostsFile=")]
            # A fresh guest on an old DHCP lease conflicts with the user's
            # ordinary known_hosts. A private, per-provisioning file is safe
            # to use for both the readiness probe and identity transfer.
            if not hosts_files or not os.path.isfile(hosts_files[0]):
                return type("Result", (), {"returncode": 255})()
            used_hosts_files.append(hosts_files[0])
            if kwargs.get("input") is not None:
                installed.append(kwargs["input"])
            return type("Result", (), {"returncode": 0})()

        with (
            patch.object(provision, "resolve_vmid", return_value=102),
            patch.object(provision, "container_address", return_value="10.3.10.155"),
            patch.object(provision, "read_age_identity", return_value=identity),
            patch.object(provision.socket, "getaddrinfo", side_effect=socket.gaierror),
            patch.object(provision.socket, "create_connection") as connection,
            patch.object(provision.subprocess, "run", side_effect=ssh_run),
            patch.object(provision.time, "monotonic", side_effect=[0, 1, 301]),
            patch.object(provision.time, "sleep"),
            redirect_stdout(io.StringIO()),
        ):
            connection.return_value.__enter__.return_value = None
            self.assertEqual(provision.cmd_create(FakePve(), args), 0)

        self.assertEqual(installed, [identity])
        self.assertEqual(len(used_hosts_files), 2)
        self.assertEqual(used_hosts_files[0], used_hosts_files[1])
        self.assertFalse(os.path.exists(used_hosts_files[0]))

    def test_cli_refuses_manual_remote_rebuild(self):
        with redirect_stdout(io.StringIO()), patch("sys.stderr", io.StringIO()):
            with self.assertRaises(SystemExit) as error:
                provision.parse_args([
                    "lxc", "ishar", "--node", "roshar",
                    "--template", "local:vztmpl/ishar.tar.xz", "--deploy", ".#ishar",
                ])
        self.assertEqual(error.exception.code, 2)


if __name__ == "__main__":
    unittest.main()
