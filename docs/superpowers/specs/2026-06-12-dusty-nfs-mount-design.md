# Dusty NFS Mount — Design

**Date:** 2026-06-12
**Purpose:** Persistently expose the `dusty-nfs` share on `truenas.local.ryk.sh` at `/mnt/dusty-nfs` on jezrien, with graceful behavior when the server is unreachable.

## Background

`truenas.local.ryk.sh` hosts a NFSv4 share named `dusty-nfs`, exported at `/mnt/default_pool/dusty-nfs`. The intent is day-to-day access from jezrien (NixOS desktop) without manual `mount` invocations.

A hard `fileSystems` mount is rejected because:

1. It blocks boot when the server is unreachable (LAN-only DNS via `*.local.ryk.sh`).
2. Even with `nofail`, an offline server makes interactive `ls /mnt/dusty-nfs` hang.

Systemd automount (on-demand mount, idle unmount) handles both cases cleanly and is the standard idiom for network-backed mounts on NixOS.

## Scope

In-scope:

- A dendritic module `modules/misc/dusty-nfs.nix` registering `flake.modules.nixos.dusty-nfs`.
- The module owns its runtime dep (`nfs-utils`).
- Wiring it into jezrien via `self.modules.nixos.dusty-nfs` in `modules/hosts/jezrien/default.nix`.
- Cleanup: remove the now-redundant `nfs-utils` entry from `modules/hosts/jezrien/_configuration.nix`.
- A comment block at the top of the module noting Darwin support was deferred.

Out-of-scope:

- Darwin (taln) support. Deferred — taln is a laptop that is often off-LAN, so `truenas.local.ryk.sh` won't resolve, and nix-darwin's autofs story requires an imperative `system.activationScripts` patch to `/etc/auto_master`. Revisit when taln genuinely needs the share.
- nixy. The LXC test container has no use for the share.
- Kerberized NFS / `sec=krb5`. Sticking with `sec=sys` (NFSv4 default) for home LAN.
- Read-only or per-user mount variants.

## Architecture

### File layout

```
modules/
  misc/
    dusty-nfs.nix        # NEW — dendritic module, NixOS-only for now

modules/hosts/jezrien/
  default.nix            # EDIT — add `self.modules.nixos.dusty-nfs`
  _configuration.nix     # EDIT — remove `nfs-utils` from systemPackages
```

### Module shape

```nix
# modules/misc/dusty-nfs.nix
#
# NFSv4 share from truenas.local.ryk.sh:/mnt/default_pool/dusty-nfs mounted at /mnt/dusty-nfs.
# Uses systemd automount: noauto + x-systemd.automount so nothing happens at
# boot — the mount is established on first access and torn down after the
# idle-timeout. Keeps the system responsive when the server is unreachable.
#
# Darwin (taln) intentionally not registered. taln is frequently off-LAN where
# *.local.ryk.sh doesn't resolve; nix-darwin also requires an imperative
# activation script to splice /etc/auto_master. Revisit if taln needs it.
{ ... }:
{
  flake.modules.nixos.dusty-nfs =
    { pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.nfs-utils ];

      fileSystems."/mnt/dusty-nfs" = {
        device = "truenas.local.ryk.sh:/mnt/default_pool/dusty-nfs";
        fsType = "nfs";
        options = [
          "x-systemd.automount"
          "noauto"
          "x-systemd.idle-timeout=600"
          "x-systemd.mount-timeout=10s"
          "x-systemd.device-timeout=10s"
          "nfsvers=4"
          "soft"
          "timeo=50"
        ];
      };
    };
}
```

Option rationale:

- `x-systemd.automount` + `noauto` — systemd creates an `.automount` unit; the actual `.mount` triggers on first I/O to `/mnt/dusty-nfs`.
- `x-systemd.idle-timeout=600` — unmount after 10 minutes of no activity, freeing the connection.
- `x-systemd.mount-timeout=10s` + `x-systemd.device-timeout=10s` — fail fast when truenas is unreachable.
- `nfsvers=4` — single port (2049), modern default.
- `soft` + `timeo=50` (5s) — `soft` lets I/O return an error instead of hanging indefinitely when the server is gone. Trade-off: under transient network blips a syscall can fail rather than wait it out. Acceptable for an interactive desktop mount; would not be acceptable for, say, a database backing store.

## Verification

1. `nix flake check` — evaluation passes, dendritic module is picked up.
2. `sudo nixos-rebuild switch --flake .#jezrien` — applies.
3. `systemctl list-unit-files | grep dusty-nfs` — shows `mnt-dusty\x2dnfs.automount` and `mnt-dusty\x2dnfs.mount`.
4. `ls /mnt/dusty-nfs` — triggers the mount; share contents appear.
5. `mount | grep dusty-nfs` — confirms mount is active.
6. Wait >10 min idle, re-check `mount` — confirms auto-unmount.
7. Disable LAN connectivity, `ls /mnt/dusty-nfs` — errors within ~10s rather than hanging.

## Open questions

None.
