# Dusty NFS Mount on Darwin (taln) — Design

**Date:** 2026-07-27
**Purpose:** Expose the `dusty-nfs` share on `truenas.local.ryk.sh` at `~/Documents/dusty-nfs` on taln (macOS), on-demand, with graceful behavior when taln is off-LAN.

## Background

The `dusty-nfs` share (`truenas.local.ryk.sh:/mnt/default_pool/dusty-nfs`, NFSv4) is already mounted on jezrien (NixOS) at `/mnt/dusty-nfs` via systemd automount — see `2026-06-12-dusty-nfs-mount-design.md`. That design **explicitly deferred Darwin**, citing two reasons: taln is frequently off-LAN where `*.local.ryk.sh` won't resolve, and nix-darwin needs an imperative activation script to splice `/etc/auto_master`.

This design implements the deferred Darwin case. The off-LAN concern is exactly why an **on-demand** mount is the right model on taln: the share only mounts when the path is accessed on-LAN, so nothing hangs at login while roaming. macOS's native on-demand mechanism is **autofs** (there is no systemd), which is the direct analogue of jezrien's `x-systemd.automount`.

## Scope

In-scope:

- Extend the existing dendritic module `modules/misc/dusty-nfs.nix` with `flake.modules.darwin.dusty-nfs` (reuse — the share/server details stay co-located with the NixOS variant).
- The Darwin variant:
  - Writes an autofs **direct map** at `/etc/auto_dusty_nfs` via `environment.etc`.
  - A `system.activationScripts.postActivation` snippet that: `mkdir -p`s the neutral mountpoint parent, idempotently splices a direct-map line into macOS's `/etc/auto_master`, and runs `automount -vc`.
  - A declarative symlink `~/Documents/dusty-nfs → /System/Volumes/Data/mnt/dusty-nfs` via home-manager `mkOutOfStoreSymlink` (following the darwin + homeManager split used by `modules/desktop/aerospace.nix`).
- Wire `self.modules.darwin.dusty-nfs` into `modules/hosts/taln/default.nix`'s module list.
- Update the module's top comment (currently "Darwin (taln) intentionally not registered") to reflect that Darwin is now supported via autofs.

Out-of-scope:

- Changing the jezrien (NixOS) variant — it stays as-is.
- nixy (LXC test container).
- Kerberized NFS / `sec=krb5` — home LAN uses `sec=sys`.
- Tuning the **global** autofs idle-unmount timeout (`/etc/autofs.conf` `AUTOMOUNT_TIMEOUT`). macOS only supports a global timeout, not per-mount; the system default is left in place. Revisit if the default proves too aggressive/lax.
- Creating `/mnt` at the filesystem root. Rejected — macOS's sealed read-only system volume would require an `/etc/synthetic.conf` entry **and a reboot**. The neutral mountpoint lives on the writable data volume instead.

## Why neutral path + symlink (Approach B)

`~/Documents` is TCC-privacy-protected on macOS. Having autofs own a mountpoint directly inside a TCC-protected directory makes on-access triggering (especially from Finder) occasionally flaky, and automountd runs as root against a user-privacy-protected path.

Instead, autofs owns a neutral mountpoint on the writable data volume, and the user-facing path is a plain symlink:

- **Mountpoint:** `/System/Volumes/Data/mnt/dusty-nfs` (writable data volume; no synthetic.conf, no reboot).
- **User path:** `~/Documents/dusty-nfs` — a symlink to the mountpoint. The symlink is an ordinary file in Documents; following it to a network mount works from the terminal, and from Finder behaves like any network volume.

## Architecture

### File layout

```
modules/misc/dusty-nfs.nix        # EDIT — add flake.modules.darwin.dusty-nfs; update top comment
modules/hosts/taln/default.nix    # EDIT — add self.modules.darwin.dusty-nfs to modules list
docs/superpowers/specs/2026-06-12-dusty-nfs-mount-design.md  # OPTIONAL — cross-link addendum
```

### Module shape (Darwin variant, added to the same file)

```nix
flake.modules.darwin.dusty-nfs =
  { pkgs, username, ... }:
  let
    mountPoint = "/System/Volumes/Data/mnt/dusty-nfs";
    userLink = "/Users/${username}/Documents/dusty-nfs";
  in
  {
    # Direct autofs map. `soft`+`timeo` mirror jezrien so I/O errors instead of
    # hanging when truenas is unreachable (taln is often off-LAN).
    # `resvport` because macOS clients otherwise use a high source port some
    # TrueNAS exports reject; harmless when not required.
    environment.etc."auto_dusty_nfs".text = ''
      ${mountPoint} -fstype=nfs,vers=4,soft,timeo=50,resvport,rw truenas.local.ryk.sh:/mnt/default_pool/dusty-nfs
    '';

    system.activationScripts.postActivation.text = ''
      # neutral mountpoint parent lives on the writable data volume
      /bin/mkdir -p "$(/usr/bin/dirname ${mountPoint})"

      # idempotently register the direct map with macOS's auto_master
      if ! /usr/bin/grep -q '/etc/auto_dusty_nfs' /etc/auto_master; then
        printf '/-\t\t\t/etc/auto_dusty_nfs\n' >> /etc/auto_master
      fi

      /usr/sbin/automount -vc || true
    '';

    # ~/Documents/dusty-nfs -> mountpoint, declarative via home-manager
    home-manager.users.${username} =
      { config, ... }:
      {
        home.file."Documents/dusty-nfs".source =
          config.lib.file.mkOutOfStoreSymlink mountPoint;
      };
  };
```

### Option rationale

- **autofs direct map** (`/-` in auto_master) — mounts on first access to the exact path, unmounts when idle. The macOS analogue of `x-systemd.automount`.
- **`vers=4`** — single-port NFSv4, matches jezrien.
- **`soft` + `timeo=50`** (5s) — return an I/O error instead of hanging when truenas is gone. Correct for an interactive, roaming laptop mount.
- **`resvport`** — macOS↔TrueNAS commonly needs the client to use a privileged source port; harmless otherwise.
- **`environment.etc` for the map** — the map file is *new* (no macOS conflict), so nix-darwin owns it cleanly in the store.
- **activation script for `/etc/auto_master`** — macOS ships and owns `auto_master`, so we splice (idempotent `grep` guard) rather than replace it. `automount -vc` reloads without reboot.
- **`mkOutOfStoreSymlink`** — the symlink target is a runtime mountpoint, not a store path, so this is the correct HM primitive.

## Verification

1. `git add` new/edited files, then `nix flake check` — evaluation passes; darwin module is picked up.
2. `darwin-rebuild switch --flake .#taln` — applies.
3. `cat /etc/auto_master` — shows the `/-  /etc/auto_dusty_nfs` line exactly once (re-run switch; confirm it is **not** duplicated).
4. `cat /etc/auto_dusty_nfs` — shows the direct map entry.
5. `readlink ~/Documents/dusty-nfs` — resolves to `/System/Volumes/Data/mnt/dusty-nfs`.
6. On-LAN: `ls ~/Documents/dusty-nfs` — triggers the mount; share contents appear. `mount | grep dusty-nfs` — confirms active NFS mount.
7. Off-LAN (or truenas down): `ls ~/Documents/dusty-nfs` — errors within a few seconds rather than hanging.

## Open questions

None. (Global idle-timeout tuning is deliberately deferred — see Out-of-scope.)
```