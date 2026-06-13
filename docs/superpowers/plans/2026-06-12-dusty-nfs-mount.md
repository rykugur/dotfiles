# Dusty NFS Mount Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a persistent on-demand NFSv4 automount of `truenas.local.ryk.sh:/mnt/dusty-nfs` at `/mnt/dusty-nfs` on jezrien.

**Architecture:** A dendritic NixOS-only module at `modules/misc/dusty-nfs.nix` declares the `fileSystems` entry with `x-systemd.automount`+`noauto` semantics and pulls in its own `nfs-utils` dep. jezrien opts in via `self.modules.nixos.dusty-nfs`. The now-redundant `nfs-utils` line in jezrien's `_configuration.nix` is removed in the same commit.

**Tech Stack:** Nix (flake-parts + import-tree dendritic pattern), NixOS, systemd automount, NFSv4.

**Note on TDD:** This codebase has no unit-test harness for module evaluation. "Verification" here means `nix flake check` (eval) for each task and a behavioral check on the host at the end. There is no per-task failing-test → green-test loop.

---

## File Structure

- **Create:** `modules/misc/dusty-nfs.nix` — registers `flake.modules.nixos.dusty-nfs`. Owns its dep (`nfs-utils`). Includes a comment block explaining why Darwin is intentionally not registered.
- **Modify:** `modules/hosts/jezrien/default.nix` — adds `self.modules.nixos.dusty-nfs` to the modules list.
- **Modify:** `modules/hosts/jezrien/_configuration.nix` — remove the redundant `nfs-utils` entry from `environment.systemPackages`.

---

## Task 1: Add the dusty-nfs dendritic module

**Files:**
- Create: `modules/misc/dusty-nfs.nix`

- [ ] **Step 1: Create the module file**

Write `modules/misc/dusty-nfs.nix` with this exact content:

```nix
# modules/misc/dusty-nfs.nix
#
# NFSv4 share from truenas.local.ryk.sh:/mnt/dusty-nfs mounted at /mnt/dusty-nfs.
# Uses systemd automount: `noauto` + `x-systemd.automount` so nothing happens at
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
        device = "truenas.local.ryk.sh:/mnt/dusty-nfs";
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

- [ ] **Step 2: Verify eval picks up the new module**

Run: `nix flake check`
Expected: Completes without error. The new module is auto-imported by `import-tree ./modules` — no other wiring is needed at this point because no host imports it yet.

- [ ] **Step 3: Commit**

```bash
git add modules/misc/dusty-nfs.nix
git commit -m "feat(nfs): add dusty-nfs dendritic module

NFSv4 share from truenas.local.ryk.sh mounted on demand at
/mnt/dusty-nfs via systemd automount. NixOS-only — Darwin
(taln) intentionally deferred."
```

---

## Task 2: Wire the module into jezrien and remove the redundant nfs-utils

**Files:**
- Modify: `modules/hosts/jezrien/default.nix` — add module reference
- Modify: `modules/hosts/jezrien/_configuration.nix` — remove redundant `nfs-utils`

- [ ] **Step 1: Locate the modules list in `modules/hosts/jezrien/default.nix`**

The file has a `modules = [ ... ]` block listing entries like `self.modules.nixos.btrfs`, `self.modules.nixos._1password`, etc. Find that block.

- [ ] **Step 2: Add the dusty-nfs module reference**

Insert `self.modules.nixos.dusty-nfs` into the modules list. Group it with the other `self.modules.nixos.*` entries — e.g. add it next to `self.modules.nixos.btrfs`:

```nix
      self.modules.nixos._1password
      self.modules.nixos.btrfs
      self.modules.nixos.dusty-nfs
      self.modules.nixos.zsa
```

(Exact neighbors don't matter as long as it's inside the `modules = [ ... ]` list.)

- [ ] **Step 3: Remove the redundant nfs-utils from jezrien's systemPackages**

In `modules/hosts/jezrien/_configuration.nix`, find the `environment.systemPackages` block. It currently contains:

```nix
    systemPackages = with pkgs; [
      nfs-utils
      via
      vial
      vulkan-tools
    ];
```

Delete the `nfs-utils` line so it becomes:

```nix
    systemPackages = with pkgs; [
      via
      vial
      vulkan-tools
    ];
```

- [ ] **Step 4: Verify eval still passes with the wiring + removal**

Run: `nix flake check`
Expected: Completes without error. If you see "attribute 'dusty-nfs' missing" the module from Task 1 isn't present — go back and re-check.

- [ ] **Step 5: Commit**

```bash
git add modules/hosts/jezrien/default.nix modules/hosts/jezrien/_configuration.nix
git commit -m "feat(jezrien): wire dusty-nfs module, drop redundant nfs-utils

nfs-utils now ships with the dusty-nfs module itself, so the
host-level entry was duplication."
```

---

## Task 3: Apply on jezrien and verify behavior

This task is run on the jezrien host (you should already be on it if you're following this plan in the dotfiles repo). It is the only behavioral check — eval-only verification in earlier tasks cannot catch a wrong mount option or unreachable server.

- [ ] **Step 1: Apply the configuration**

Run: `sudo nixos-rebuild switch --flake .#jezrien`
Expected: Build succeeds, switch completes, no errors about the new mount unit.

- [ ] **Step 2: Confirm the systemd automount unit exists**

Run: `systemctl list-unit-files | grep dusty`
Expected output (escape characters render the `-` in the path):
```
mnt-dusty\x2dnfs.automount      static
mnt-dusty\x2dnfs.mount          generated
```

- [ ] **Step 3: Trigger the mount and verify it works**

Run: `ls /mnt/dusty-nfs`
Expected: The directory listing of the TrueNAS share appears. (If it's empty, that's still success — the mount happened.)

Run: `mount | grep dusty-nfs`
Expected: A line of the form
```
truenas.local.ryk.sh:/mnt/dusty-nfs on /mnt/dusty-nfs type nfs4 (rw,...)
```

- [ ] **Step 4: Confirm the offline-fail-fast behavior (optional sanity check)**

Pick one:

(a) Quick way without disrupting your network: run `sudo umount /mnt/dusty-nfs` then immediately `time ls /mnt/dusty-nfs`. The mount should re-trigger and return promptly while truenas is reachable.

(b) True offline test: temporarily block traffic to truenas (`sudo ip route add blackhole $(getent hosts truenas.local.ryk.sh | awk '{print $1}')`), then `sudo umount /mnt/dusty-nfs` and `time ls /mnt/dusty-nfs`. Expected: command errors within ~10s (not a hang). Clean up the route with `sudo ip route del blackhole <ip>` afterwards.

Skip this step if you don't want to fiddle with routes — the unit-file + successful-mount checks already prove the config landed correctly.

- [ ] **Step 5: No commit needed**

This task only verifies; the code commits were made in Tasks 1 and 2.

---

## Done criteria

- `modules/misc/dusty-nfs.nix` exists and registers `flake.modules.nixos.dusty-nfs`.
- `nix flake check` passes.
- `sudo nixos-rebuild switch --flake .#jezrien` succeeds.
- `ls /mnt/dusty-nfs` returns the share contents.
- `nfs-utils` appears in `modules/misc/dusty-nfs.nix` and NOT in `modules/hosts/jezrien/_configuration.nix`.
