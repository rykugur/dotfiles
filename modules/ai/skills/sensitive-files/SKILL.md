---
name: sensitive-files
description: Never read files that typically contain secrets — env files, sops-encrypted YAML, terraform variables, ssh keys, age keys, and similar. Use this skill any time you are about to read, grep, or list a file matching the patterns below; refuse and explain instead.
---

# Sensitive files — do not read

This repo (and most repos the user works in) contains files that hold credentials, private keys, or other secrets. Reading them into the conversation leaks those secrets into model context, logs, and potentially across tool boundaries. Don't do it.

## Files to refuse

Treat any path matching one of these patterns as off-limits. Do not `read`, `cat`, `grep`, `head`, `tail`, `bat`, or `less` on it. Do not include its contents in tool calls. Do not write its contents into other files.

- `*.env`, `*.env.*`, `.env`, `.env.local`, `.env.production`, etc.
- `*.sops.yaml`, `*.sops.yml`, `*.sops.json` — sops-encrypted files (even encrypted, treat as sensitive)
- `*.tfvars`, `*.tfvars.json` — terraform variable files often holding cloud credentials
- `.envrc` — direnv file may export secrets
- `secrets.yaml`, `secrets.yml`, `secrets.json`, `secrets.nix` (when not sops-encrypted on disk)
- SSH and signing keys: `id_rsa`, `id_ed25519`, `id_ecdsa`, anything under `~/.ssh/` that isn't `.pub`
- Age/PGP keys: `*.age`, `*.asc`, `keys.txt` in an age context
- AWS / GCP credential files: `~/.aws/credentials`, `~/.config/gcloud/credentials.db`, service-account JSON
- npm/cargo/pypi tokens: `.npmrc` (with `_authToken`), `~/.cargo/credentials.toml`, `~/.pypirc`
- Anything obviously named `*secret*`, `*credential*`, `*token*`, `*password*` outside of public docs/tests

## What to do instead

When the user asks for help on something that touches these files:

- If you need to know the file *exists*: `ls` the directory (don't open the file).
- If you need to know the file's *structure*: ask the user, or read a `.env.example` / sibling template if present.
- If you need to *modify* one of these files: have the user paste a redacted version of the relevant block, or write the new content based on the user's description without reading the existing.
- If the user explicitly tells you to read one anyway: confirm once ("This file looks like it may contain secrets — proceed?"), then comply. The skill is a default, not an absolute bar.

## Why a skill instead of a permission gate

The pi-permission-system used here can ask/deny per *tool* name but not per *file path*. So we can't say "deny read on `*.env`" the way opencode does. This skill is the substitute: soft guidance the agent applies before invoking read tools. It relies on you reading and following it. Take it seriously.
