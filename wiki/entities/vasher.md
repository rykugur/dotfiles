---
title: Vasher
category: entity
date: 2026-07-30
tags: [vasher, nixos, binary-cache, prebuild, caddy, react, lxc]
sources: ["modules/hosts/vasher/_role.nix", "modules/nixos/vasher-cache.nix", "modules/nixos/vasher-prebuild.nix", "modules/nixos/vasher-prebuild.sh", "scripts/vasher-promote.sh"]
related: ["../hosts.md", "../architecture.md", "../modules.md"]
---

# Vasher

Vasher is the LAN-only NixOS build-cache host for Jezrien. It runs in Proxmox LXC CT 200, builds Jezrien’s reduced system closure, signs and serves the resulting store paths through Harmonia, and never receives interactive Nix builds from Jezrien. It separates expensive evaluation/build work from desktop activation: Jezrien substitutes matching paths from Vasher, then builds only closure misses locally. Promotion remains an explicit, fast-forward-only Git operation.

## Role and boundaries

- **Platform**: `x86_64-linux` NixOS; initially a Proxmox LXC and designed to migrate to bare metal without changing its cache/prebuild role modules.
- **Cache**: Harmonia serves signed Nix paths at `http://vasher.local.ryk.sh:5000/`; Jezrien trusts Vasher’s dedicated cache key and treats it solely as a substituter.
- **Not a remote builder**: `nix.buildMachines` and SSH build delegation are intentionally absent. Vasher does not build arbitrary local desktop changes.
- **Prebuild target**: `nixosConfigurations.jezrien-prebuild.config.system.build.toplevel`, which omits `bambu-studio`; the normal Jezrien configuration still builds that package locally when needed.
- **Resources**: the LXC has 4 CPU cores, 12 GiB RAM, and 2 GiB swap. Nix schedules one derivation at a time with four build cores (`max-jobs = 1`, `cores = 4`).

## Candidate lifecycle

`vasher-prebuild-refresh` runs 15 minutes after its prior completion. It fetches `origin/master`; when `cache-bump` already covers that revision it records `idle`, otherwise it creates a serialized candidate build. `vasher-prebuild-candidate` forces the same flow nightly at 03:00 with up to 10 minutes randomized delay.

Each run works from a detached Git worktree. It refreshes flake inputs, updates Oh My Pi only in the candidate flow, builds the reduced Jezrien closure, retains the output as a GC root, then checks that `origin/master` is still exactly the revision it began from. If master advanced, the candidate is marked `stale`, its newly created root is discarded, and nothing is published. Only a successful, current candidate force-with-lease updates the disposable `cache-bump` branch. Five successful closure roots are retained under `/var/lib/vasher/gcroots`.

## Promotion

Promotion is deliberately separate from building. On a clean local `master` checkout, run [`scripts/vasher-promote.sh`](../../scripts/vasher-promote.sh). It verifies that `origin/cache-bump` descends from the checked-out master, fast-forwards master to that exact candidate, pushes master, and invokes the local NixOS switch. It refuses stale, unrelated, dirty, or non-master states instead of reconciling them.

## Status dashboard

The prebuild runtime writes only curated, atomic state below `/var/lib/vasher/dashboard`:

- `status.json`: current lifecycle state (`idle`, `building`, `success`, `failed`, or `stale`), revisions, timestamps, target output, exclusions, and optional exit code.
- `history.json`: newest-first terminal history, limited to 20 entries.
- `log.txt`: latest 200 captured build-output lines.

A static React dashboard, built by Nix and styled with Catppuccin Mocha, polls those files every five seconds. Caddy serves the dashboard and exactly those files at `http://vasher.local.ryk.sh:5080/`; it has no write endpoints, journal endpoint, TLS/public-DNS exposure, Node process, SSR, or general-purpose API. If status files do not exist yet, the page explicitly reports that it is awaiting Vasher status.

## Deployment and operations

After the intended commit is available on GitHub, deploy the Vasher role without starting a build:

```bash
ssh root@vasher.local.ryk.sh \
  'nixos-rebuild switch --refresh --flake github:rykugur/dotfiles#vasher'
```

Confirm the cache service, timers, and dashboard:

```bash
ssh root@vasher.local.ryk.sh \
  'systemctl is-active harmonia caddy; systemctl list-timers vasher-prebuild-refresh.timer vasher-prebuild-candidate.timer --no-pager'
curl --fail http://vasher.local.ryk.sh:5080/
```

To populate status immediately, run the normal refresh path rather than bypassing the lifecycle:

```bash
ssh root@vasher.local.ryk.sh 'systemctl start vasher-prebuild-refresh.service'
```

### Cross-references

- [Hosts](../hosts.md)
- [Architecture](../architecture.md)
- [Modules](../modules.md)
