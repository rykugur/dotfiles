# Dusty NFS Mount on Darwin (taln) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Mount the `dusty-nfs` NFS share on taln (macOS) on-demand, exposed at `~/Documents/dusty-nfs`, declaratively via nix-darwin + autofs.

**Architecture:** Extend the existing dendritic module `modules/misc/dusty-nfs.nix` with a `flake.modules.darwin.dusty-nfs` variant. It writes an autofs direct map, splices macOS's `/etc/auto_master` in a `postActivation` script, and symlinks `~/Documents/dusty-nfs` to a neutral data-volume mountpoint via home-manager. Wired into `hosts/taln/default.nix`.

**Tech Stack:** Nix, flake-parts (dendritic modules), nix-darwin, home-manager, macOS autofs.

## Global Constraints

- Nix flake is **pure** — new/edited files must be `git add`ed before `nix flake check` / `darwin-rebuild` or they are invisible to evaluation.
- Reuse the existing `modules/misc/dusty-nfs.nix`; do **not** create a second NFS module. The NixOS variant in that file stays unchanged.
- Mountpoint (real): `/System/Volumes/Data/mnt/dusty-nfs`. User-facing path: `/Users/dusty/Documents/dusty-nfs` (symlink).
- Share: `truenas.local.ryk.sh:/mnt/default_pool/dusty-nfs`, NFSv4, options `vers=4,soft,timeo=50,resvport,rw`.
- Follow the darwin + homeManager module split used by `modules/desktop/aerospace.nix`.
- Commit messages end with the `Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>` trailer.

---

### Task 1: Add the Darwin variant and wire it into taln

**Files:**
- Modify: `modules/misc/dusty-nfs.nix` (add `flake.modules.darwin.dusty-nfs`; update top comment)
- Modify: `modules/hosts/taln/default.nix` (add `self.modules.darwin.dusty-nfs` to the modules list)

**Interfaces:**
- Consumes: nix-darwin module args `pkgs`, `username`; home-manager arg `config` (for `config.lib.file.mkOutOfStoreSymlink`).
- Produces: `self.modules.darwin.dusty-nfs`, consumed by `modules/hosts/taln/default.nix`.

- [ ] **Step 1: Update the top-of-file comment**

In `modules/misc/dusty-nfs.nix`, replace the existing Darwin-deferral paragraph (lines beginning "Darwin (taln) intentionally not registered.") with:

```nix
# Darwin (taln) is supported via autofs: `flake.modules.darwin.dusty-nfs`
# writes a direct map, splices /etc/auto_master in a postActivation script, and
# symlinks ~/Documents/dusty-nfs to a neutral data-volume mountpoint. On-demand
# autofs keeps taln responsive when off-LAN (truenas.local.ryk.sh won't resolve).
```

- [ ] **Step 2: Add the Darwin module**

In `modules/misc/dusty-nfs.nix`, add a second attribute alongside `flake.modules.nixos.dusty-nfs` (inside the same top-level attrset):

```nix
  flake.modules.darwin.dusty-nfs =
    { username, ... }:
    let
      mountPoint = "/System/Volumes/Data/mnt/dusty-nfs";
    in
    {
      # Direct autofs map. soft+timeo mirror jezrien so I/O errors instead of
      # hanging when truenas is unreachable (taln is often off-LAN). resvport
      # because macOS clients otherwise use a high source port some TrueNAS
      # exports reject; harmless when not required.
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

- [ ] **Step 3: Wire the module into taln**

In `modules/hosts/taln/default.nix`, add to the `modules = [ ... ]` list, next to the other `self.modules.darwin.*` entries:

```nix
      self.modules.darwin.dusty-nfs
```

- [ ] **Step 4: Stage the changes (pure flake requirement)**

Run: `git add modules/misc/dusty-nfs.nix modules/hosts/taln/default.nix`
Expected: no output, exit 0.

- [ ] **Step 5: Evaluate the flake**

Run: `nix flake check 2>&1 | tail -20`
Expected: no evaluation errors. If it reports the darwin config, the module is picked up.

Fallback if `nix flake check` is slow or evaluates unrelated systems, evaluate just taln:

Run: `nix eval .#darwinConfigurations.taln.config.environment.etc."auto_dusty_nfs".text --raw`
Expected: prints the direct-map line containing `/System/Volumes/Data/mnt/dusty-nfs` and `truenas.local.ryk.sh:/mnt/default_pool/dusty-nfs`.

- [ ] **Step 6: Commit**

```bash
git commit -m "feat(dusty-nfs): mount share on taln via autofs

Add flake.modules.darwin.dusty-nfs: direct autofs map to a neutral
data-volume mountpoint, /etc/auto_master splice in postActivation, and a
home-manager symlink at ~/Documents/dusty-nfs. Wired into taln.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 2: Apply to taln and verify the mount

**Files:** none (runtime verification on the live taln system).

**Interfaces:**
- Consumes: the committed `self.modules.darwin.dusty-nfs` from Task 1.

- [ ] **Step 1: Apply the configuration**

Run: `darwin-rebuild switch --flake .#taln`
Expected: builds and activates without error; activation output shows the postActivation script running.

- [ ] **Step 2: Verify auto_master was spliced exactly once**

Run: `grep -c '/etc/auto_dusty_nfs' /etc/auto_master`
Expected: `1`. (Re-run `darwin-rebuild switch` and re-check — must still be `1`, proving idempotency.)

- [ ] **Step 3: Verify the map file and symlink**

Run: `cat /etc/auto_dusty_nfs`
Expected: the direct-map line to `/System/Volumes/Data/mnt/dusty-nfs`.

Run: `readlink ~/Documents/dusty-nfs`
Expected: `/System/Volumes/Data/mnt/dusty-nfs`.

- [ ] **Step 4: Trigger the mount (on-LAN)**

Run: `ls ~/Documents/dusty-nfs`
Expected (on-LAN): share contents listed.

Run: `mount | grep dusty-nfs`
Expected: an active NFS mount at `/System/Volumes/Data/mnt/dusty-nfs`.

- [ ] **Step 5: Verify graceful failure (off-LAN / server down)**

Run (only when off-LAN or truenas is unreachable): `time ls ~/Documents/dusty-nfs`
Expected: errors within a few seconds rather than hanging indefinitely.

- [ ] **Step 6: Update the wiki**

Per `CLAUDE.md`, ingest this change so knowledge compounds. Add a note to the relevant wiki page (e.g. `wiki/` hosts/modules section) that taln now mounts `dusty-nfs` via autofs at `~/Documents/dusty-nfs`, linking the spec `docs/superpowers/specs/2026-07-27-dusty-nfs-darwin-design.md`. Commit:

```bash
git add wiki
git commit -m "docs(wiki): ingest dusty-nfs autofs mount on taln

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Self-Review

**Spec coverage:**
- Extend `dusty-nfs.nix` with darwin variant → Task 1 Step 2. ✓
- autofs direct map via `environment.etc` → Task 1 Step 2. ✓
- `postActivation` mkdir + auto_master splice + `automount -vc` → Task 1 Step 2. ✓
- home-manager `mkOutOfStoreSymlink` for `~/Documents/dusty-nfs` → Task 1 Step 2. ✓
- Wire into `hosts/taln/default.nix` → Task 1 Step 3. ✓
- Update deferral comment → Task 1 Step 1. ✓
- Global idle-timeout untouched (out of scope) → not implemented, as intended. ✓
- Verification steps (auto_master once, map, symlink, trigger, graceful fail) → Task 2. ✓
- Wiki ingest (CLAUDE.md requirement) → Task 2 Step 6. ✓

**Placeholder scan:** No TBD/TODO; all code and commands are concrete. ✓

**Type consistency:** `mountPoint` binding used consistently; `auto_dusty_nfs` filename matches between `environment.etc`, the `grep` guard, the `printf` line, and verification. `username` arg used for both the auto_master path context and the HM symlink. ✓
