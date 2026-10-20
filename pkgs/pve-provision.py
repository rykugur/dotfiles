"""Provision Proxmox LXC containers from NixOS-built templates.

Talks to the Proxmox VE REST API with an API token. Everything it needs is
reachable by a non-root token:

  POST /nodes/{node}/storage/{storage}/upload   Datastore.AllocateTemplate
  POST /nodes/{node}/lxc                        VM.Allocate on the pool,
                                                Datastore.AllocateSpace,
                                                VM.Config.*, SDN.Use on the bridge
  POST /nodes/{node}/lxc/{vmid}/status/start    VM.PowerMgmt

Guardrails, because an agent may call this:
  * every container is created into a managed pool,
  * destroy refuses any guest outside that pool,
  * create never overwrites an existing vmid.
"""

import argparse
import hashlib
import http.client
import json
import os
import shutil
import socket
import ssl
import subprocess
import sys
import time
import urllib.parse
import uuid

DEFAULT_POOL = "agent-managed"
# PVE validates the extension of an uploaded template.
VZTMPL_SUFFIXES = (".tar", ".tar.gz", ".tar.xz", ".tar.zst", ".tar.bz2")


class ProvisionError(Exception):
    pass


def log(message):
    print(message, file=sys.stderr, flush=True)


class ChainedBody:
    """A read-only file-like object concatenating bytes, a file, bytes.

    Lets http.client stream a multi-gigabyte template without building the
    whole multipart body in memory or on disk.
    """

    def __init__(self, prologue, path, epilogue):
        self.parts = [prologue, None, epilogue]
        self.path = path
        self.index = 0
        self.handle = None

    def read(self, size=-1):
        while self.index < len(self.parts):
            part = self.parts[self.index]
            if part is None:
                if self.handle is None:
                    self.handle = open(self.path, "rb")
                chunk = self.handle.read(size if size and size > 0 else 65536)
                if chunk:
                    return chunk
                self.handle.close()
                self.handle = None
                self.index += 1
                continue
            if part:
                if size is None or size < 0 or size >= len(part):
                    self.parts[self.index] = b""
                    self.index += 1
                    return part
                self.parts[self.index] = part[size:]
                return part[:size]
            self.index += 1
        return b""


class Pve:
    def __init__(self, url, token, ca_file=None, insecure=False, timeout=60):
        parsed = urllib.parse.urlparse(url)
        if parsed.scheme != "https" or not parsed.hostname:
            raise ProvisionError(f"--url must be an https URL, got {url!r}")
        self.host = parsed.hostname
        self.port = parsed.port or 8006
        self.base = parsed.path.rstrip("/") + "/api2/json"
        self.token = token
        self.timeout = timeout
        if insecure:
            self.context = ssl._create_unverified_context()
        else:
            self.context = ssl.create_default_context(cafile=ca_file)

    def _connect(self):
        return http.client.HTTPSConnection(
            self.host, self.port, timeout=self.timeout, context=self.context
        )

    def _headers(self, extra=None):
        headers = {
            "Authorization": f"PVEAPIToken={self.token}",
            "Accept": "application/json",
        }
        if extra:
            headers.update(extra)
        return headers

    def request(self, method, path, params=None):
        body = None
        headers = {}
        target = self.base + path
        if params and method == "GET":
            target += "?" + urllib.parse.urlencode(params)
        elif params:
            body = urllib.parse.urlencode(params)
            headers["Content-Type"] = "application/x-www-form-urlencoded"
        conn = self._connect()
        try:
            conn.request(method, target, body=body, headers=self._headers(headers))
            return self._read(conn.getresponse(), method, path)
        finally:
            conn.close()

    def upload(self, node, storage, path, filename, checksum=None):
        boundary = uuid.uuid4().hex
        fields = [("content", "vztmpl")]
        if checksum:
            # The algorithm must precede the checksum: pveproxy validates each
            # part as it parses it, and `checksum` requires `checksum-algorithm`.
            fields += [("checksum-algorithm", "sha256"), ("checksum", checksum)]
        prologue = b""
        for name, value in fields:
            prologue += (
                f"--{boundary}\r\n"
                f'Content-Disposition: form-data; name="{name}"\r\n\r\n'
                f"{value}\r\n"
            ).encode()
        prologue += (
            f"--{boundary}\r\n"
            f'Content-Disposition: form-data; name="filename"; filename="{filename}"\r\n'
            f"Content-Type: application/octet-stream\r\n\r\n"
        ).encode()
        epilogue = f"\r\n--{boundary}--\r\n".encode()
        length = len(prologue) + os.path.getsize(path) + len(epilogue)
        headers = {
            "Content-Type": f"multipart/form-data; boundary={boundary}",
            "Content-Length": str(length),
        }
        target = f"{self.base}/nodes/{node}/storage/{storage}/upload"
        conn = self._connect()
        conn.timeout = max(self.timeout, 1800)
        try:
            conn.request(
                "POST",
                target,
                body=ChainedBody(prologue, path, epilogue),
                headers=self._headers(headers),
            )
            return self._read(conn.getresponse(), "POST", target)
        finally:
            conn.close()

    @staticmethod
    def _read(response, method, path):
        raw = response.read()
        if response.status == 401:
            raise ProvisionError(
                "401 from Proxmox: the API token is missing, wrong, or lacks "
                "privilege separation permissions"
            )
        if response.status >= 400:
            detail = raw.decode("utf-8", "replace").strip()
            raise ProvisionError(f"{method} {path} failed: {response.status} {detail}")
        if not raw:
            return None
        return json.loads(raw).get("data")

    def wait_task(self, node, upid, what, poll=2.0, timeout=3600):
        if not upid:
            return
        deadline = time.monotonic() + timeout
        quoted = urllib.parse.quote(upid, safe="")
        while True:
            status = self.request("GET", f"/nodes/{node}/tasks/{quoted}/status") or {}
            if status.get("status") == "stopped":
                exit_status = status.get("exitstatus")
                if exit_status != "OK":
                    raise ProvisionError(f"{what} failed: {exit_status}")
                return
            if time.monotonic() > deadline:
                raise ProvisionError(f"{what} did not finish within {timeout}s")
            time.sleep(poll)


def sha256_file(path):
    digest = hashlib.sha256()
    with open(path, "rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def build_image(attr):
    log(f"building {attr}")
    out = subprocess.run(
        ["nix", "build", "--no-link", "--print-out-paths", attr],
        check=True,
        capture_output=True,
        text=True,
    ).stdout.split()
    if not out:
        raise ProvisionError(f"{attr} produced no output path")
    return find_template(out[-1])


def find_template(path):
    if os.path.isfile(path):
        return path
    candidates = []
    for root, _dirs, files in os.walk(path):
        for name in files:
            if name.endswith(VZTMPL_SUFFIXES):
                candidates.append(os.path.join(root, name))
    if not candidates:
        raise ProvisionError(f"no template tarball under {path}")
    if len(candidates) > 1:
        raise ProvisionError(f"ambiguous templates under {path}: {sorted(candidates)}")
    return candidates[0]


def guest_index(pve):
    resources = pve.request("GET", "/cluster/resources", {"type": "vm"}) or []
    return {int(entry["vmid"]): entry for entry in resources if "vmid" in entry}


def resolve_vmid(pve, requested):
    existing = guest_index(pve)
    if requested is not None:
        if requested in existing:
            entry = existing[requested]
            raise ProvisionError(
                f"vmid {requested} already exists "
                f"({entry.get('name')} on {entry.get('node')}); refusing to touch it"
            )
        return requested
    return int(pve.request("GET", "/cluster/nextid"))


def ensure_template(pve, args, local_path):
    filename = args.template_name or f"{args.hostname}-{os.path.basename(local_path)}"
    if not filename.endswith(VZTMPL_SUFFIXES):
        raise ProvisionError(
            f"template name {filename!r} must end in one of {VZTMPL_SUFFIXES}"
        )
    volid = f"{args.template_storage}:vztmpl/{filename}"
    try:
        content = (
            pve.request(
                "GET",
                f"/nodes/{args.node}/storage/{args.template_storage}/content",
                {"content": "vztmpl"},
            )
            or []
        )
    except ProvisionError as exc:
        # Listing needs Datastore.Audit; upload only needs AllocateTemplate.
        if " 403 " not in str(exc):
            raise
        log(f"cannot list {args.template_storage} content ({exc}); uploading")
        content = []
    size = os.path.getsize(local_path)
    for entry in content:
        if entry.get("volid") == volid:
            if int(entry.get("size") or 0) == size:
                log(f"template already present: {volid}")
                return volid
            raise ProvisionError(
                f"{volid} exists with a different size; pick another --template-name"
            )
    log(f"uploading {local_path} -> {volid} ({size / 1048576:.0f} MiB)")
    upid = pve.upload(
        args.node,
        args.template_storage,
        local_path,
        filename,
        checksum=sha256_file(local_path),
    )
    pve.wait_task(args.node, upid, "template upload")
    return volid


def container_address(pve, node, vmid, timeout=120):
    """Find the container's address once DHCP has settled.

    Needed because a fresh CT's hostname may not be in DNS yet.
    """
    deadline = time.monotonic() + timeout
    while True:
        try:
            interfaces = pve.request("GET", f"/nodes/{node}/lxc/{vmid}/interfaces") or []
        except ProvisionError:
            interfaces = []
        for entry in interfaces:
            if entry.get("name") in ("lo", None):
                continue
            inet = entry.get("inet")
            if inet:
                return inet.split("/")[0]
        if time.monotonic() > deadline:
            return None
        time.sleep(5)


def wait_for_ssh(host, user, timeout=300):
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        try:
            with socket.create_connection((host, 22), timeout=5):
                pass
            probe = subprocess.run(
                [
                    "ssh",
                    "-o",
                    "BatchMode=yes",
                    "-o",
                    "StrictHostKeyChecking=accept-new",
                    "-o",
                    "ConnectTimeout=5",
                    f"{user}@{host}",
                    "true",
                ],
                capture_output=True,
            )
            if probe.returncode == 0:
                return True
        except OSError:
            pass
        time.sleep(5)
    return False


def read_age_identity(key_file=None, sops_file=None):
    """Load the age identity, decrypting it in memory when it is sops-encrypted."""
    if sops_file:
        key = subprocess.run(
            ["sops", "--decrypt", "--input-type", "binary", "--output-type", "binary", sops_file],
            check=True,
            capture_output=True,
        ).stdout
        source = sops_file
    else:
        with open(key_file, "rb") as handle:
            key = handle.read()
        source = key_file
    if b"AGE-SECRET-KEY-" not in key:
        raise ProvisionError(f"{source} does not contain an age identity")
    return key


def install_age_key(host, user, key):
    """Push the host's sops-nix age identity.

    This is what removes the chicken-and-egg: the identity is generated once,
    kept encrypted in the repo, and injected at provision time, so a rebuilt
    container keeps decrypting the same secrets.yaml.
    """
    log("installing sops-nix age identity")
    subprocess.run(
        [
            "ssh",
            "-o",
            "BatchMode=yes",
            "-o",
            "StrictHostKeyChecking=accept-new",
            f"{user}@{host}",
            "install -d -m 0755 /var/lib/sops-nix && "
            "install -m 0600 /dev/stdin /var/lib/sops-nix/key.txt",
        ],
        input=key,
        check=True,
    )


def deploy(attr, host, user):
    log(f"deploying {attr} to {host}")
    subprocess.run(
        [
            "nixos-rebuild",
            "switch",
            "--flake",
            attr,
            "--target-host",
            f"{user}@{host}",
        ],
        check=True,
    )


def cmd_list(pve, args):
    rows = []
    for vmid, entry in sorted(guest_index(pve).items()):
        rows.append(
            {
                "vmid": vmid,
                "name": entry.get("name"),
                "type": entry.get("type"),
                "node": entry.get("node"),
                "status": entry.get("status"),
                "pool": entry.get("pool"),
            }
        )
    if args.json:
        print(json.dumps(rows, indent=2))
        return 0
    for row in rows:
        print(
            f"{row['vmid']:>6}  {row['type']:<4} {row['status']:<8} "
            f"{row['node']:<10} {row['pool'] or '-':<16} {row['name'] or ''}"
        )
    return 0


def cmd_create(pve, args):
    if args.build:
        local_path = build_image(args.build)
    elif args.file:
        local_path = find_template(args.file)
    elif not args.template:
        raise ProvisionError("one of --build, --file or --template is required")
    volid = args.template
    if not volid:
        volid = ensure_template(pve, args, local_path)

    vmid = resolve_vmid(pve, args.vmid)
    net = f"name=eth0,bridge={args.bridge},ip={args.ip}"
    if args.gateway:
        net += f",gw={args.gateway}"
    params = {
        "vmid": vmid,
        "ostemplate": volid,
        "hostname": args.hostname,
        "cores": args.cores,
        "memory": args.memory,
        "swap": args.swap,
        "rootfs": f"{args.rootfs_storage}:{args.disk}",
        "net0": net,
        "unprivileged": 1,
        "onboot": 1 if args.onboot else 0,
        "pool": args.pool,
        "start": 0,
    }
    if args.nesting:
        # Unprivileged NixOS containers need this: without it systemd comes up
        # far enough for a getty but activation never finishes, so there is no
        # /run/current-system, no system profile, and no DHCP client.
        # It is also the only feature flag a non-root token may set.
        params["features"] = "nesting=1"
    if args.description:
        params["description"] = args.description

    if args.dry_run:
        print(json.dumps({"vmid": vmid, "node": args.node, "params": params}, indent=2))
        return 0

    log(f"creating CT {vmid} ({args.hostname}) on {args.node} in pool {args.pool}")
    upid = pve.request("POST", f"/nodes/{args.node}/lxc", params)
    pve.wait_task(args.node, upid, f"create CT {vmid}")

    if args.start:
        log(f"starting CT {vmid}")
        upid = pve.request("POST", f"/nodes/{args.node}/lxc/{vmid}/status/start")
        pve.wait_task(args.node, upid, f"start CT {vmid}")

    target = args.ssh_host or args.hostname
    want_key = args.age_key_file or args.age_key_sops
    if want_key or args.deploy:
        if not args.start:
            raise ProvisionError("--age-key-*/--deploy require the container to start")
        if not args.ssh_host:
            try:
                socket.getaddrinfo(target, 22)
            except socket.gaierror:
                # A brand new CT is usually not in DNS yet.
                address = container_address(pve, args.node, vmid)
                if not address:
                    raise ProvisionError(
                        f"{target} does not resolve and CT {vmid} reported no address; "
                        "pass --ssh-host"
                    )
                log(f"{target} does not resolve yet; using {address}")
                target = address
        log(f"waiting for ssh on {target}")
        if not wait_for_ssh(target, args.ssh_user):
            raise ProvisionError(f"no ssh on {target} after the container started")
        if want_key:
            key = read_age_identity(args.age_key_file, args.age_key_sops)
            install_age_key(target, args.ssh_user, key)
        if args.deploy:
            deploy(args.deploy, target, args.ssh_user)

    print(
        json.dumps(
            {"vmid": vmid, "node": args.node, "hostname": args.hostname, "target": target}
        )
    )
    return 0


def cmd_status(pve, args):
    entry = guest_index(pve).get(args.vmid)
    if not entry:
        raise ProvisionError(f"vmid {args.vmid} not found")
    node = entry.get("node")
    status = pve.request("GET", f"/nodes/{node}/lxc/{args.vmid}/status/current")
    print(json.dumps({"resource": entry, "status": status}, indent=2))
    return 0


def pool_members(pve, pool):
    """vmids in a pool, read from the pool itself.

    `/cluster/resources` can report `pool: null` for a guest that is in one
    (stale cache, or missing Pool.Audit), and this decides whether destroy is
    allowed, so ask the authoritative endpoint.
    """
    data = pve.request("GET", f"/pools/{pool}") or {}
    return {int(m["vmid"]) for m in data.get("members", []) if "vmid" in m}


def cmd_destroy(pve, args):
    entry = guest_index(pve).get(args.vmid)
    if not entry:
        raise ProvisionError(f"vmid {args.vmid} not found")
    if args.vmid not in pool_members(pve, args.pool):
        raise ProvisionError(
            f"vmid {args.vmid} is not a member of pool {args.pool}; refusing"
        )
    node = entry.get("node")
    if entry.get("status") == "running":
        if not args.force_stop:
            raise ProvisionError(f"CT {args.vmid} is running; pass --force-stop")
        upid = pve.request("POST", f"/nodes/{node}/lxc/{args.vmid}/status/stop")
        pve.wait_task(node, upid, f"stop CT {args.vmid}")
    upid = pve.request("DELETE", f"/nodes/{node}/lxc/{args.vmid}")
    pve.wait_task(node, upid, f"destroy CT {args.vmid}")
    print(json.dumps({"destroyed": args.vmid}))
    return 0


def read_token(args):
    if os.environ.get("PVE_API_TOKEN"):
        return os.environ["PVE_API_TOKEN"].strip()
    path = args.token_file
    if not path:
        raise ProvisionError("set PVE_API_TOKEN or pass --token-file")
    try:
        with open(path, "r", encoding="utf-8") as handle:
            token = handle.read().strip()
    except OSError as exc:
        raise ProvisionError(f"cannot read token file {path}: {exc}") from exc
    if "!" not in token or "=" not in token:
        raise ProvisionError(f"{path} must contain user@realm!tokenid=uuid")
    return token


def parse_args(argv):
    parser = argparse.ArgumentParser(
        prog="pve-provision",
        description="Build a NixOS LXC template, upload it, and provision a Proxmox CT.",
    )
    parser.add_argument(
        "--url",
        default=os.environ.get("PVE_API_URL"),
        help="Proxmox API base, e.g. https://roshar.local.ryk.sh:8006",
    )
    parser.add_argument(
        "--token-file",
        default=os.environ.get("PVE_API_TOKEN_FILE", "/run/secrets/pve_api_token"),
    )
    parser.add_argument("--ca-file", default=os.environ.get("PVE_CA_FILE"))
    parser.add_argument(
        "--insecure",
        action="store_true",
        help="skip TLS verification (only for nodes with an untrusted certificate)",
    )
    parser.add_argument("--json", action="store_true")
    sub = parser.add_subparsers(dest="command", required=True)

    listing = sub.add_parser("list", help="list guests")
    listing.set_defaults(func=cmd_list)

    create = sub.add_parser("lxc", help="create an LXC from a NixOS template")
    create.add_argument("hostname")
    create.add_argument("--node", required=True)
    source = create.add_mutually_exclusive_group(required=True)
    source.add_argument("--build", help="flake attr to build, e.g. .#hoid-lxc-image")
    source.add_argument("--file", help="prebuilt template tarball or result directory")
    source.add_argument("--template", help="existing volid, e.g. local:vztmpl/x.tar.xz")
    create.add_argument("--template-storage", default="local")
    create.add_argument("--template-name")
    create.add_argument("--rootfs-storage", default="local-lvm")
    create.add_argument("--disk", type=int, default=32, help="rootfs size in GiB")
    create.add_argument("--cores", type=int, default=2)
    create.add_argument("--memory", type=int, default=4096)
    create.add_argument("--swap", type=int, default=512)
    create.add_argument("--bridge", default="vmbr0")
    create.add_argument("--ip", default="dhcp")
    create.add_argument("--gateway")
    create.add_argument("--vmid", type=int)
    create.add_argument("--pool", default=DEFAULT_POOL)
    create.add_argument("--description")
    create.add_argument("--nesting", action="store_true", default=True)
    create.add_argument("--no-nesting", dest="nesting", action="store_false")
    create.add_argument("--onboot", action="store_true", default=True)
    create.add_argument("--no-onboot", dest="onboot", action="store_false")
    create.add_argument("--start", action="store_true", default=True)
    create.add_argument("--no-start", dest="start", action="store_false")
    create.add_argument("--ssh-host", help="address to reach the CT on (default: hostname)")
    create.add_argument("--ssh-user", default="root")
    create.add_argument(
        "--age-key-file",
        help="plaintext sops-nix age identity to install at /var/lib/sops-nix/key.txt",
    )
    create.add_argument(
        "--age-key-sops",
        help="sops-encrypted age identity (decrypted in memory, never written locally)",
    )
    create.add_argument("--deploy", help="flake attr to nixos-rebuild onto the new CT")
    create.add_argument("--dry-run", action="store_true")
    create.set_defaults(func=cmd_create)

    status = sub.add_parser("status", help="show one guest")
    status.add_argument("vmid", type=int)
    status.set_defaults(func=cmd_status)

    destroy = sub.add_parser("destroy", help="destroy a guest in the managed pool")
    destroy.add_argument("vmid", type=int)
    destroy.add_argument("--pool", default=DEFAULT_POOL)
    destroy.add_argument("--force-stop", action="store_true")
    destroy.set_defaults(func=cmd_destroy)

    return parser.parse_args(argv)


def main(argv=None):
    args = parse_args(argv if argv is not None else sys.argv[1:])
    try:
        if not args.url:
            raise ProvisionError("set PVE_API_URL or pass --url")
        if getattr(args, "deploy", None) and not shutil.which("nixos-rebuild"):
            raise ProvisionError("--deploy needs nixos-rebuild on PATH")
        pve = Pve(
            args.url,
            read_token(args),
            ca_file=args.ca_file,
            insecure=args.insecure,
        )
        return args.func(pve, args)
    except ProvisionError as exc:
        log(f"pve-provision: {exc}")
        return 1
    except subprocess.CalledProcessError as exc:
        log(f"pve-provision: command failed: {exc}")
        return 1
    except KeyboardInterrupt:
        return 130


if __name__ == "__main__":
    sys.exit(main())
