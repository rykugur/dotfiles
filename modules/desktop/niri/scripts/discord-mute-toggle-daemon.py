#!/usr/bin/env python3
"""Persistent daemon holding one authenticated connection to Discord's local
RPC socket, exposing mute-toggle over a lightweight Unix control socket.

Discord's RPC IPC server throttles each new incoming connection by roughly
10-30s (reproduced with a raw synchronous socket connect+handshake, so this
is not an asyncio/pypresence artifact - Discord itself is slow to respond).
Reconnecting once per keypress made the F13 hotkey take 15-30s to register.
Keeping a single connection open and only sending the toggle command over
it is what makes the hotkey instant.

DISCORD_CLIENT_ID_FILE / DISCORD_CLIENT_SECRET_FILE must point at files
containing a Discord application's client_id/client_secret (scope "rpc",
redirect http://localhost:7878, Installation Contexts: User Install). On
first run (no cached token) Discord shows an in-app authorize popup -
accept it once; the token is cached to
~/.cache/discord-mute-toggle-token.json and reused on every subsequent
daemon start/reconnect.
"""
import asyncio
import json
import os
import sys
import urllib.parse
import urllib.request
from pathlib import Path

from pypresence import AioClient

REDIRECT_URI = "http://localhost:7878"
TOKEN_FILE = Path.home() / ".cache" / "discord-mute-toggle-token.json"
SOCK_PATH = Path(os.environ.get("XDG_RUNTIME_DIR", "/tmp")) / "discord-mute-toggle.sock"
RECONNECT_DELAY_S = 5

TOKEN_EXCHANGE_HEADERS = {
    "Content-Type": "application/x-www-form-urlencoded",
    # Discord's Cloudflare WAF (error 1010) blocks the default urllib user
    # agent on this endpoint.
    "User-Agent": (
        "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 "
        "(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
    ),
}


def read_secret(env_var: str) -> str:
    path = os.environ.get(env_var)
    if not path:
        sys.exit(f"{env_var} is not set")
    return Path(path).read_text().strip()


def exchange_code(client_id: str, client_secret: str, code: str) -> dict:
    data = urllib.parse.urlencode(
        {
            "client_id": client_id,
            "client_secret": client_secret,
            "grant_type": "authorization_code",
            "code": code,
            "redirect_uri": REDIRECT_URI,
        }
    ).encode()
    req = urllib.request.Request(
        "https://discord.com/api/oauth2/token", data=data, headers=TOKEN_EXCHANGE_HEADERS
    )
    with urllib.request.urlopen(req) as resp:
        return json.loads(resp.read())


async def get_token(client: AioClient, client_id: str, client_secret: str) -> str:
    if TOKEN_FILE.exists():
        return json.loads(TOKEN_FILE.read_text())["access_token"]

    print("No cached token - waiting for the authorize click in Discord...", flush=True)
    auth = await client.authorize(client_id, scopes=["rpc"])
    loop = asyncio.get_running_loop()
    token = await loop.run_in_executor(
        None, exchange_code, client_id, client_secret, auth["data"]["code"]
    )
    TOKEN_FILE.parent.mkdir(parents=True, exist_ok=True)
    TOKEN_FILE.write_text(json.dumps(token))
    TOKEN_FILE.chmod(0o600)
    return token["access_token"]


async def run_session(client_id: str, client_secret: str) -> None:
    client = AioClient(client_id=client_id, response_timeout=60)
    await client.start()
    token = await get_token(client, client_id, client_secret)
    await client.authenticate(token)
    print("Authenticated with Discord RPC.", flush=True)

    broken = asyncio.Event()

    async def handle(reader: asyncio.StreamReader, writer: asyncio.StreamWriter) -> None:
        try:
            await reader.read(1)
            settings = await client.get_voice_settings()
            muted = settings["data"]["mute"]
            await client.set_voice_settings(mute=not muted)
            writer.write(b"ok\n")
        except Exception as exc:  # noqa: BLE001 - reported to caller, then forces a reconnect
            writer.write(f"error: {exc}\n".encode())
            broken.set()
        finally:
            await writer.drain()
            writer.close()

    if SOCK_PATH.exists():
        SOCK_PATH.unlink()

    server = await asyncio.start_unix_server(handle, path=str(SOCK_PATH))
    async with server:
        serve_task = asyncio.create_task(server.serve_forever())
        await broken.wait()
        serve_task.cancel()

    raise RuntimeError("Discord RPC connection lost")


async def main() -> None:
    client_id = read_secret("DISCORD_CLIENT_ID_FILE")
    client_secret = read_secret("DISCORD_CLIENT_SECRET_FILE")

    while True:
        try:
            await run_session(client_id, client_secret)
        except Exception as exc:  # noqa: BLE001 - keep the daemon alive across Discord restarts
            print(f"session ended: {exc!r}; reconnecting in {RECONNECT_DELAY_S}s", flush=True)
            await asyncio.sleep(RECONNECT_DELAY_S)


if __name__ == "__main__":
    asyncio.run(main())
