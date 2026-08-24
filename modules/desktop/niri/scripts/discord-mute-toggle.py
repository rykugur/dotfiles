#!/usr/bin/env python3
"""Trigger client for discord-mute-toggle-daemon.

Sends one byte to the daemon's Unix control socket and waits for the ack.
The slow parts (Discord RPC connect/auth, which Discord's IPC server
throttles by ~10-30s per new connection) live in the daemon's single
long-lived connection, so this is near-instant - safe to bind directly to
a hotkey.
"""
import os
import socket
import sys
from pathlib import Path

SOCK_PATH = Path(os.environ.get("XDG_RUNTIME_DIR", "/tmp")) / "discord-mute-toggle.sock"


def main() -> None:
    try:
        with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as s:
            s.settimeout(5)
            s.connect(str(SOCK_PATH))
            s.sendall(b"\n")
            reply = s.recv(256).decode().strip()
    except (FileNotFoundError, ConnectionRefusedError):
        sys.exit(f"discord-mute-toggle-daemon is not running (no socket at {SOCK_PATH})")
    except OSError as exc:
        sys.exit(f"failed to reach discord-mute-toggle-daemon: {exc}")

    if reply != "ok":
        sys.exit(reply or "unknown error from discord-mute-toggle-daemon")


if __name__ == "__main__":
    main()
