# Vasher Resource-Control Design

**Date:** 2026-07-25  
**Status:** Approved design; awaiting written-spec review

## Purpose

Keep Vasher's nightly candidate prebuild unattended and reliable while preserving Jezrien's explicit weekly promotion decision. A previous candidate run exhausted the LXC's 8 GiB RAM and swap because its Nix daemon had no local build-concurrency limits.

## Decisions

### LXC resource envelope

CT 200 (`vasher`) uses:

- 4 vCPUs;
- 12 GiB RAM (`12288` MiB);
- 2 GiB swap (`2048` MiB).

The operator has already applied the memory and swap values to the live CT. The bootstrap script becomes the declarative recreation default, so a future CT rebuild does not regress them.

### Nix build concurrency

Vasher configures:

```nix
nix.settings = {
  max-jobs = 1;
  cores = 4;
};
```

`max-jobs = 1` permits only one derivation build at a time. `cores = 4` lets that single build use Vasher's allocated CPUs. This prevents several compiler/linker processes from independently consuming memory while retaining useful throughput for the sole active derivation.

### Update and promotion cadence

The existing candidate timer remains nightly. Each successful run updates the candidate lockfile, builds Jezrien's closure, retains its outputs, serves them through Harmonia, and updates `cache-bump`.

Jezrien promotion remains manual. The operator consumes the current tested `cache-bump` candidate weekly, or at any chosen time, with `scripts/vasher-promote.sh`. Vasher never switches or changes Jezrien automatically.

## Failure and recovery

A failed candidate writes `last-build.json` with `status: "failed"`, does not push `cache-bump`, and retains the prior successful roots. The next nightly timer retries normally.

If a build threatens host responsiveness, stop only the candidate service from the Proxmox host:

```bash
pct exec 200 -- /run/current-system/sw/bin/systemctl stop vasher-prebuild-candidate.service
```

If the CT cannot execute a command under memory pressure, use the Proxmox host's graceful shutdown path:

```bash
pct shutdown 200 --timeout 60
```

`pct stop 200` is an emergency-only abrupt stop.

## Implementation scope

1. Change `scripts/bootstrap/proxmox-lxc-create.sh` to create the 12 GiB / 2 GiB CT envelope.
2. Add the Nix concurrency settings to `modules/hosts/vasher/_role.nix`.
3. Add focused regression coverage for the bootstrap resource arguments and evaluated Vasher Nix settings.
4. Document deployment and verification commands in `wiki/hosts.md`.

## Out of scope

- Changing the nightly candidate timer.
- Automatic `cache-bump` promotion or automatic Jezrien switching.
- Adding service cgroup memory limits; Nix daemon build concurrency is the direct cause and control point.
- Changing Vasher CPU allocation, cache retention, cache signing, or SSH policy.

## Acceptance criteria

- A bootstrap-created Vasher CT declares 4 cores, `12288` MiB memory, and `2048` MiB swap.
- Evaluated Vasher Nix settings expose `max-jobs = 1` and `cores = 4`.
- The candidate timer remains nightly.
- The deployment procedure applies the configuration without restarting a candidate build unexpectedly.
- A detached manually started candidate completes without exhausting CT memory or swap, and records success in `/var/lib/vasher/last-build.json`.
