---
title: Vasher
category: entity
date: 2026-10-12
tags: [vasher, nixos, binary-cache, prebuild, caddy, react, lxc, agent, hermes, monitor, holds]
sources: ["modules/hosts/vasher/_role.nix", "modules/nixos/vasher-cache.nix", "modules/nixos/vasher-prebuild.nix", "modules/nixos/vasher-prebuild.sh", "modules/nixos/vasher-prebuild-monitor.py", "modules/nixos/vasher-agent-verb.py", "modules/nixos/vasher-dashboard/src/main.tsx", "modules/ai/vasher-supervisor.nix", "modules/ai/vasher-supervise.sh", "modules/ai/skills/vasher-supervisor/SKILL.md", "scripts/vasher-promote.sh"]
related: ["../hosts.md", "../architecture.md", "../modules.md"]
---

# Vasher

Vasher is the LAN-only NixOS build-cache host for Jezrien. It runs in a dedicated LXC, builds Jezrien’s reduced system closure, signs and serves the resulting store paths through Harmonia, and never receives interactive Nix builds from Jezrien. It separates expensive evaluation/build work from desktop activation: Jezrien substitutes matching paths from Vasher, then builds only closure misses locally. Promotion remains an explicit, fast-forward-only Git operation.

## Role and boundaries

- **Platform**: `x86_64-linux` NixOS; initially an LXC and designed to migrate to bare metal without changing its cache/prebuild role modules.
- **Cache**: Harmonia serves signed Nix paths through a LAN-only endpoint; Jezrien trusts Vasher’s dedicated cache key and treats it solely as a substituter.
- **Not a remote builder**: `nix.buildMachines` and SSH build delegation are intentionally absent. Vasher does not build arbitrary local desktop changes.
- **Prebuild target**: `nixosConfigurations.jezrien-prebuild.config.system.build.toplevel`, which omits `bambu-studio`; the normal Jezrien configuration still builds that package locally when needed.
- **Resources**: Nix schedules one derivation at a time within a fixed LXC resource envelope.

## Candidate lifecycle

`vasher-prebuild-refresh` runs 15 minutes after its prior completion. It fetches `origin/master`. It records `idle` when `cache-bump` already covers that revision. Otherwise, it creates a serialized candidate build. `vasher-prebuild-candidate` forces the same flow nightly at 03:00 with up to 10 minutes of random delay.

Each run works from a detached Git worktree. It refreshes flake inputs, builds the reduced Jezrien closure, retains the output as a GC root, then checks that `origin/master` is still exactly the revision it began from. If master advanced, the candidate is marked `stale`, its newly created root is discarded, and nothing is published. Only a successful, current candidate force-with-lease updates the disposable `cache-bump` branch. A small set of successful closure roots is retained.

An active hold pins one flake input to a known revision until its expiry date. The full candidate flow updates all other inputs. Expired holds and unknown input names do not change the update. If every input is held, the flow skips the flake update and still applies the Oh My Pi release bump.

Narrow mode is a recovery path. It updates only the requested inputs, except for held inputs, and keeps the normal build and publication gates. A failed narrow build cannot move `cache-bump`.

## Local monitor and remote supervisor

The local monitor on Vasher makes every real-time safety decision with fixed rules. It watches the build, storage, memory, and disk space. It can stop an unsafe build and run the existing one-time recovery path. It does not accept model output as a safety decision.

The remote Hermes supervisor runs on the `hermes` container, which is always on. It polls read-only data from Vasher and asks Hermes to explain new incidents. Hermes can propose an action, but Vasher validates and decides it. Healthy polls make zero model calls. Alerts go to the journal, and to a Hermes gateway channel when `ryk.vasherSupervisor.sendTarget` names one.

The regular supervisor runs every 30 minutes, except Monday at 09:00. The weekly digest owns that time and always calls Hermes. Each Hermes run uses `hermes --toolsets todo --ignore-rules --skills vasher-supervisor --oneshot` and has a 300-second limit. The harmless todo-only toolset keeps untrusted event and build-log text away from shell, file, and network tools.

## Agent action channel

The channel accepts four verb names: `retry-exact`, `narrow-inputs`, `hold-input`, and `release-input`. Each request is one bounded JSON object. The channel applies fixed preconditions and never passes request text to a shell.

SSH forces the `vasher-agent-verb` command and disables command selection, forwarding, and terminal allocation. The `vasher-agent` user cannot read the Git deploy key or GitHub token. It can write only under `/var/lib/vasher/agent`.

The channel serializes requests with `channel.lock`. It accepts at most 8 requests and rejects at most 32 requests in a rolling 24-hour period. It reads standard input for at most 10 seconds. It logs denials to syslog and uses unique temporary files for atomic writes.

The channel is inactive until an operator installs a dedicated key pair. Add the public key to `ryk.vasherPrebuild.agentKeys` on Vasher. Put the matching private key at `/var/lib/hermes/.ssh/vasher-agent` on the `hermes` container. Do not use an operator key for this channel.

## Storage-fault halt

The monitor scans failed build logs for storage-error signatures. After each failed build, it also reads btrfs error counters when sysfs is readable and compares them with the previous readable failed-build sample; it does not sample those counters continuously. A detected error writes `/var/lib/vasher/monitor/storage-fault.json`, records `needs-attention`, and prevents a retry.

All prebuild modes stop while the fault file exists. They record `blocked` without noise, and an absent revision is valid in that state. The agent cannot remove the file. After the operator repairs or replaces the disk, clear the halt with:

```bash
sudo rm /var/lib/vasher/monitor/storage-fault.json
```

Only an operator runs this command.

## Promotion

Promotion is deliberately separate from building. On a clean local `master` checkout, run [`scripts/vasher-promote.sh`](../../scripts/vasher-promote.sh). It verifies that `origin/cache-bump` descends from the checked-out master, fast-forwards master to that exact candidate, pushes master, and invokes the local NixOS switch. It refuses stale, unrelated, dirty, or non-master states instead of reconciling them.

## Status dashboard

The prebuild runtime writes curated state with atomic file replacement:

- `status.json`: The current lifecycle state, revisions, timestamps, target output, exclusions, and optional exit code.
- `history.json`: The newest-first terminal history, limited to 20 entries.
- `log.txt`: The latest 200 captured build-output lines.

A static React dashboard polls these files every five seconds. Caddy also provides two read-only event endpoints:

- `/api/events.json`: Monitor events from `/var/lib/vasher/dashboard/events.json`.
- `/api/agent-events.json`: Agent events from `/var/lib/vasher/agent/events.json`.

The frontend merges the two event lists. The separate files preserve write ownership. The monitor writes its ledger, and the channel writes only its agent-owned ledger. Agent event and hold endpoint failures degrade independently, show an unavailable message, and do not hide trusted monitor status. A 404 represents an empty optional ledger and is not degradation.

The dashboard also reads `/api/holds.json` and shows active or expired holds. Caddy serves no write endpoint, journal endpoint, public DNS endpoint, or general-purpose API. The dashboard has no Node server or server-side rendering process.

## Deployment and operations

Deploy the Vasher role with the normal NixOS rebuild for the published flake's `vasher` configuration. Deployment applies the configuration only. It does not start a build.

Before actions can work, seed the `hermes` container's `/var/lib/hermes/.ssh/known_hosts` with Vasher's verified runtime host key. Then add the dedicated public key to `ryk.vasherPrebuild.agentKeys` on Vasher and put its private key at `/var/lib/hermes/.ssh/vasher-agent`. The supervisor remains read-only when this key is absent. After deployment, run the real `hold-input` and `release-input` smoke test over SSH and confirm the agent ledger and `/api/holds.json`.

Make sure that the cache service, timers, dashboard, and curated API files work from the trusted LAN. To populate status immediately, start `vasher-prebuild-refresh.service`. This uses the normal serialized lifecycle.

### Cross-references

- [Hosts](../hosts.md)
- [Architecture](../architecture.md)
- [Modules](../modules.md)
