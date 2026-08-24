#!/usr/bin/env python3
"""Toggle Discord mute via its local RPC socket.

Unlike Discord's in-app hotkey capture, this talks to the RPC socket
directly, so it works regardless of window focus (fixes global mute under
niri/XWayland, where Discord only sees hotkeys while an X11 surface has
focus).

Requires DISCORD_CLIENT_ID_FILE and DISCORD_CLIENT_SECRET_FILE to point at
files containing a Discord application's client_id/client_secret
(https://discord.com/developers/applications, OAuth2 redirect
http://localhost:7878, scope "rpc"). On first run Discord shows an
authorize popup - accept it once; the resulting token is cached at
~/.cache/discord-mute-toggle-token.json for subsequent runs.
"""
import json
import os
import sys
import urllib.parse
import urllib.request
from pathlib import Path

from pypresence import Client

REDIRECT_URI = "http://localhost:7878"
TOKEN_FILE = Path.home() / ".cache" / "discord-mute-toggle-token.json"


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
        "https://discord.com/api/oauth2/token",
        data=data,
        headers={"Content-Type": "application/x-www-form-urlencoded"},
    )
    with urllib.request.urlopen(req) as resp:
        return json.loads(resp.read())


def get_token(client: Client, client_id: str, client_secret: str) -> str:
    if TOKEN_FILE.exists():
        return json.loads(TOKEN_FILE.read_text())["access_token"]

    auth = client.authorize(client_id, scopes=["rpc"])
    token = exchange_code(client_id, client_secret, auth["data"]["code"])
    TOKEN_FILE.parent.mkdir(parents=True, exist_ok=True)
    TOKEN_FILE.write_text(json.dumps(token))
    TOKEN_FILE.chmod(0o600)
    return token["access_token"]


def main() -> None:
    client_id = read_secret("DISCORD_CLIENT_ID_FILE")
    client_secret = read_secret("DISCORD_CLIENT_SECRET_FILE")

    client = Client(client_id=client_id)
    client.start()
    token = get_token(client, client_id, client_secret)
    client.authenticate(token)

    settings = client.get_voice_settings()
    currently_muted = settings["data"]["mute"]
    client.set_voice_settings(mute=not currently_muted)
    client.close()


if __name__ == "__main__":
    main()
