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
- **Resources**: CT 300 on roshar has 8 GiB RAM, 2 GiB swap, and a ~100 GiB disk. Nix runs one derivation and one substitution at a time; its daemon/build workers have `MemoryHigh=5G`, `MemoryMax=6G`, `MemorySwapMax=512M`. Each prebuild client, including retry, and the separate cleanup client have `MemoryMax=1G`, `MemorySwapMax=512M`. The client limit also covers flake evaluation. These are failure limits, not a guarantee that every evaluation or package fits; an oversized job fails rather than consuming the whole CT.

## Candidate lifecycle

The refresh timer normally runs 15 minutes after its prior completion and the candidate timer normally runs nightly at 03:00. **Both timers are declaratively disabled during the first bounded trial.** An operator starts a candidate manually; simply starting a service does not re-enable its timer. Re-enable the timers in the NixOS module only after a successful observed run. Refresh records `idle` when `cache-bump` already covers `origin/master`; otherwise it creates a serialized candidate.

Each run works from a detached Git worktree. It refreshes flake inputs, builds the reduced Jezrien closure, retains the output as a GC root, then checks that `origin/master` is still exactly the revision it began from. If master advanced, the candidate is marked `stale`, its newly created root is discarded, and nothing is published. Only a successful, current candidate force-with-lease updates the disposable `cache-bump` branch. A small set of successful closure roots is retained. A failed build leaves unrooted store paths in place for reuse by an exact retry; a new run collects garbage only when `/nix` has less than 45 GiB free, and refuses to build if collection cannot restore that reserve. Successful builds prune old roots and collect garbage. If GC cannot restore 45 GiB, an operator must inspect disk use and remove only confirmed obsolete roots or expand storage; the gate intentionally does not discard retained successful closures.

An active hold pins one flake input to a known revision until its expiry date. The full candidate flow updates all other inputs. Expired holds and unknown input names do not change the update. If every input is held, the flow skips the flake update and still applies the Oh My Pi release bump.

Narrow mode is a recovery path. It updates only the requested inputs, except for held inputs, and keeps the normal build and publication gates. A failed narrow build cannot move `cache-bump`.

## Local monitor and remote supervisor

The local monitor on Vasher makes every real-time safety decision with fixed rules. It watches the build, storage, memory, and disk space. If `systemctl show` stalls or fails, it reads service cgroups directly so a runaway refresh is still visible; an unreadable cgroup produces a monitor error rather than invented safe metrics. Stops and starts have bounded waits and escalate failures to `needs-attention`. A refresh safety stop ends in `needs-attention` without cleanup or automatic retry, including after an interrupted stop. A candidate retry avoids garbage collection when at least 45 GiB is free. It does not accept model output as a safety decision.

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

The changes are built locally on Jezrien; the CT only receives and activates the closure. From the reviewed dotfiles working tree on Jezrien, verify `ssh root@vasher` connects without `sudo`, then run `nixos-rebuild build --flake .#vasher`. For deployment **by the operator**, run `nixos-rebuild switch --flake .#vasher --target-host root@vasher` (not `sudo` locally: that would use root's SSH identity). The positional `.#vasher` alone is not a flake selection; `--flake` is required. No `--build-host` is needed: absent that flag, the build stays local and the closure is copied to Vasher for root activation. Deployment itself does not start a prebuild while the two timers are disabled.

Before actions can work, seed the `hermes` container's `/var/lib/hermes/.ssh/known_hosts` with Vasher's verified runtime host key. Then add the dedicated public key to `ryk.vasherPrebuild.agentKeys` on Vasher and put its private key at `/var/lib/hermes/.ssh/vasher-agent`. The supervisor remains read-only when this key is absent. After deployment, run the real `hold-input` and `release-input` smoke test over SSH and confirm the agent ledger and `/api/holds.json`.

Before the manual trial, confirm `systemctl is-active nix-daemon.socket harmonia.service caddy.service vasher-prebuild-monitor.service`, `systemctl list-timers --all 'vasher-prebuild-*'`, `systemctl show nix-daemon.service -p MemoryHigh -p MemoryMax -p MemorySwapMax`, and `df -h /nix` over SSH. If a timer remained active from an old generation, stop it before the trial. Then run `ssh root@vasher 'systemctl start --no-block vasher-prebuild-candidate.service'` **once**. Watch `journalctl -fu vasher-prebuild-candidate.service -u vasher-prebuild-monitor.service`, `/var/lib/vasher/dashboard/status.json`, free memory and swap, and `/nix` free space. A successful `status.json` must include an output and an actual GC root under `/var/lib/vasher/gcroots/`; verify Harmonia still serves `/nix-cache-info`. On a failure, inspect the monitor's event ledger and journal rather than retrying blindly. Keep both timers disabled until a successful run has been observed and a subsequent change re-enables them declaratively.

### Cross-references

- [Hosts](../hosts.md)
- [Architecture](../architecture.md)
- [Modules](../modules.md)
