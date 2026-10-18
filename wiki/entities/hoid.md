---
title: Hoid
category: entity
date: 2026-10-18
tags: [hoid, agent, omp, collab, auth-broker, lxc, proxmox, ttyd, tailscale]
sources: ["modules/hosts/hoid/default.nix", "modules/hosts/hoid/_role.nix", "modules/hosts/hoid/_platform-lxc.nix", "modules/hosts/hoid/_seed.nix", "modules/hosts/hoid/_image.nix", "modules/ai/omp-host.nix", "modules/dev/helix-lxc.nix"]
related: ["../hosts.md", "../ai-agents.md", "vasher.md"]
---

# Hoid

Always-on OMP agent container on roshar. It runs one supervised interactive OMP
session that publishes a Collab room, so the agent is reachable from a phone
browser, and it hosts the OMP auth-broker credential vault. Named for the
Cosmere worldhopper, following the existing host naming.

Hoid is a flake-managed host (`nixosConfigurations.hoid`), not a thin
`nixos-lxc` CT. That choice is deliberate: see [Why in-flake](#why-in-flake).

## Shape

| Piece | Where | Notes |
|---|---|---|
| Agent session | `systemd.services.omp-agent` | `dtach -N` master in the foreground, so systemd supervises a real process and `Restart=always` works. OMP gets a pty from dtach, which `collab.autoStart` requires. |
| Collab room | `collab.autoStart = control` | Set through a `--config` overlay, never by writing `~/.omp/agent/config.yml` (that file holds oauth and onboarding state). |
| Terminal | `services.ttyd` on `lo:7681` | Entry point is `dtach -a /run/omp/agent.sock`, i.e. the *same* session. Covers what Collab guests cannot do: `/model`, `/compact`, `/resume`, `!bash`, `$python`. |
| Link dispenser | `omp-collab-link` on `127.0.0.1:7682` | `GET /` → 302 to the current control URL; `GET /json` adds session id, generation and busy. Re-lists on every request because the room generation changes on `/new`, `/resume` and `/fork`, and `collab link` refuses a stale generation. |
| Credential vault | `omp auth-broker serve` on `127.0.0.1:8765` | Clients opt in with `auth.broker.url` / `OMP_AUTH_BROKER_URL`. |

All four listen on loopback. Exposure is the operator's job (`tailscale serve`);
the module has no `openFirewall`.

Options live under `ryk.ompHost` in `modules/ai/omp-host.nix`, which is a
reusable NixOS module — nothing in it is hoid-specific.

## Approval model

`ryk.ompHost.approvalMode` defaults to `write`: reads and workspace writes are
auto-approved, every `exec` call (bash, eval, task) prompts. Those prompts are
answerable from a Collab guest — verified on 2026-10-18 by approving a `bash`
call from a 390 px browser viewport and watching it run on the host.

Two caveats from OMP's approval docs that matter here:

- `bash.patterns` rules do not cover the same command run through `eval`. Pair
  any deny list with a `tools.approval.eval` policy.
- Subagents always run `yolo` and a call that resolves to `prompt` *fails* in a
  headless subagent. Heavy `task` use needs the policy tuned.

## Why in-flake

The `hermes` CT (CT 200) is the counter-example. It is a thin `nixos-lxc`
container that updates only when someone SSHes in and runs `nixos-lxc-update`.
On 2026-10-18 it was still running a 2026-10-13 lock, so
`flake.modules.nixos.vasher-supervisor` — documented in this wiki and in
Arcanum as running there since 2026-10-14 — had never been deployed: no timers,
no wrapper, no state directory.

Hoid holds broker credentials and (later) a kubeconfig and a Proxmox token.
Silent drift is least acceptable there. In-flake gives reviewable diffs,
`nix flake check` coverage, rollback by flake rev, and deployment from Jezrien
with `nixos-rebuild --flake .#hoid --target-host dusty@hoid --sudo`, so the
2-vCPU container never evaluates nixpkgs itself and reuses
[Vasher](vasher.md)'s cache.

## Isolation caveat

Hoid runs on roshar and is intended to manage roshar. An agent there can
power-cycle its own container and Vasher's, and it is down whenever roshar is
down. Mitigations, none of them implemented yet:

- Proxmox API token scoped to a pool that excludes CT 200/300, `PVEAuditor` at
  `/` for inventory, `VM.PowerMgmt` only inside that pool;
- a recovery path that is not the agent (Proxmox web UI over Tailscale);
- tailnet ACLs restricting hoid to `8006`, `6443`, and named CT ports.

## Install

1. Build the CT template: `nix build .#hoid-lxc-image` (the `proxmox-lxc`
   NixOS module builds the tarball itself; no `nixos-generators`).
2. Create an unprivileged CT on roshar from that template. The seed system only
   brings up DHCP networking and SSH with root keys.
3. Push the real closure from Jezrien:
   `nixos-rebuild switch --flake .#hoid --target-host root@hoid`. After the
   first switch root login is disabled; later deploys use
   `--target-host dusty@hoid --sudo`.
4. On the container: `tailscale up`, then `tailscale serve` for ttyd and the
   link dispenser. No auth key is baked into the closure.
5. Sign the broker in: `omp auth-broker login anthropic --via=dusty@hoid`
   forwards the OAuth callback port from a workstation, so the headless
   container never needs a browser.

## Open items

- No `secrets.yaml` yet, so the shared `ssh` NixOS module (which wires a
  sops-backed private key) is not imported; `_role.nix` inlines the server
  config and the operator keys instead.
- k3s ServiceAccount, Proxmox API token, and tailnet ACLs are not written.
- `ryk.ompHost.ttyd.passwordFile` exists but is unset; ttyd currently relies on
  the loopback bind plus whatever fronts it.
