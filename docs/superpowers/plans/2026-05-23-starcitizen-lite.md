# starcitizen-lite Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a NixOS + home-manager module (`starcitizen-lite`) that handles the LUG-required system prep for Star Citizen (sysctl, nofile limits, kernel modules, joystick udev, opentrack/gameglass) without pulling in the currently broken `programs.rsi-launcher` path from nix-citizen, and wire it into jezrien.

**Architecture:** Dendritic flake module exposing `flake.modules.nixos.starcitizen-lite` and `flake.modules.homeManager.starcitizen-lite`. Import-to-enable (no `mkEnableOption`), matching `steam.nix` / `lutris.nix` / `jackify.nix`. The existing disabled `starcitizen.nix` stays in tree so it can be re-enabled when upstream nix-gaming fixes the dxvk regression.

**Tech Stack:** Nix flake-parts (dendritic style), home-manager as NixOS module, nix-citizen (only for `gameglass` and `wine-astral` package outputs — not its NixOS module), sops-nix.

**Spec:** `docs/superpowers/specs/2026-05-23-starcitizen-lite-design.md`

**Adaptation note:** This is a pure Nix config change. There is no test framework in this repo, and TDD doesn't apply. The equivalents are:
- `nix flake check` — evaluates all flake outputs (catches syntax, eval, type errors in the new module)
- `nixos-rebuild build --flake .#jezrien` — full system closure build without activation (catches every error except activation-time problems)

The plan uses these as the verification gates. Activation (`switch`) is out of scope — the user runs it from the merged master after review.

---

### Task 1: Create the starcitizen-lite module

**Files:**
- Create: `modules/gaming/starcitizen-lite.nix`

- [ ] **Step 1: Write the module**

Create `modules/gaming/starcitizen-lite.nix` with the following exact contents:

```nix
{ inputs, self, ... }:
{
  flake.modules.nixos.starcitizen-lite =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      username = config.ryk.username;
    in
    {
      # LUG prereqs — https://wiki.starcitizen-lug.org/Alternative-Installations
      # Values match nix-citizen's (which exceed the LUG floor of 1048576 / 524288).
      boot.kernel.sysctl = {
        "vm.max_map_count" = lib.mkOverride 999 16777216;
        "fs.file-max" = lib.mkOverride 999 524288;
      };

      security.pam.loginLimits = [
        {
          domain = "*";
          type = "soft";
          item = "nofile";
          value = "16777216";
        }
        {
          domain = "*";
          type = "hard";
          item = "nofile";
          value = "16777216";
        }
      ];

      # Kernel modules nix-citizen sets up for SC's audio/video pipeline.
      boot.extraModulePackages = with config.boot.kernelPackages; [ v4l2loopback ];
      boot.kernelModules =
        [ "snd-aloop" ]
        ++ lib.optional (lib.versionAtLeast config.boot.kernelPackages.kernel.version "6.14") "ntsync";

      services.udev = {
        enable = true;
        # lug-helper bundles joystick/HOTAS udev rules. services.udev.packages
        # pulls only /etc/udev/rules.d from the package — the GUI binary stays
        # out of the system closure unless explicitly added to systemPackages.
        packages = [ pkgs.lug-helper ];
        extraRules = ''
          # Set the "uaccess" tag for raw HID access for Virpil Devices in wine
          KERNEL=="hidraw*", ATTRS{idVendor}=="3344", ATTRS{idProduct}=="*", MODE="0660", TAG+="uaccess"
        '';
      };

      nix.settings = {
        substituters = [
          "https://nix-citizen.cachix.org"
          "https://nix-gaming.cachix.org"
        ];
        trusted-public-keys = [
          "nix-citizen.cachix.org-1:lPMkWc2X8XD4/7YPEEwXKKBg+SVbYTVrAaLA2wQTKCo="
          "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="
        ];
      };

      home-manager.users.${username}.imports = [ self.modules.homeManager.starcitizen-lite ];
    };

  flake.modules.homeManager.starcitizen-lite =
    { pkgs, ... }:
    let
      sys = pkgs.stdenv.hostPlatform.system;
      gameglass = inputs.nix-citizen.packages.${sys}.gameglass;
      wineAstralPkg = inputs.nix-citizen.packages.${sys}.wine-astral;
    in
    {
      home.packages = with pkgs; [
        opentrack-StarCitizen
        gameglass
      ];

      # opentrack needs a wine prefix on disk to talk to the SC wine instance.
      home.file.".wine-astral".source = wineAstralPkg;

      xdg.desktopEntries.gameglass = {
        name = "GameGlass";
        icon = "gameglass";
        exec = "${gameglass}/bin/gameglass";
        terminal = false;
        type = "Application";
        categories = [
          "Game"
          "Utility"
        ];
      };
    };
}
```

- [ ] **Step 2: Verify the flake still evaluates**

Run:
```bash
nix flake check --no-build
```

Expected: exits 0 with no errors. `--no-build` skips building derivations so the check is fast (~10–30s) and only validates eval. If it fails, the error message will name the offending file and line.

Note: at this point the new module is defined but not imported anywhere, so it doesn't get pulled into any host's closure. The check just verifies the new file itself evaluates and doesn't break the rest of the flake.

- [ ] **Step 3: Commit**

```bash
git add modules/gaming/starcitizen-lite.nix
git commit -m "feat: add starcitizen-lite module

Provides the LUG-required system prep (sysctl, nofile limits, kernel
modules, joystick/HOTAS udev) plus opentrack-StarCitizen and gameglass,
without pulling in the currently broken programs.rsi-launcher path from
nix-citizen. Game install and launch are left to Lutris."
```

---

### Task 2: Wire starcitizen-lite into jezrien

**Files:**
- Modify: `modules/hosts/jezrien/default.nix` (lines 32–35)

- [ ] **Step 1: Update the disabled-starcitizen comment and add starcitizen-lite to imports**

In `modules/hosts/jezrien/default.nix`, replace the existing disabled block:

```nix
      # disabled: nix-gaming dxvk strictDeps/structuredAttrs regression breaks
      # rsi-launcher eval (cross-spliced through wineprefix-preparer). Using
      # Lutris instead until upstream nix-gaming fixes it.
      # self.modules.nixos.starcitizen
```

with:

```nix
      # disabled: nix-gaming dxvk strictDeps/structuredAttrs regression breaks
      # rsi-launcher eval (cross-spliced through wineprefix-preparer).
      # starcitizen-lite below provides the LUG prereqs without the broken
      # launcher path; re-enable this once upstream nix-gaming is fixed.
      # self.modules.nixos.starcitizen
      self.modules.nixos.starcitizen-lite
```

The `Edit` tool call (exact `old_string` / `new_string`):

- `old_string`:
  ```
        # disabled: nix-gaming dxvk strictDeps/structuredAttrs regression breaks
        # rsi-launcher eval (cross-spliced through wineprefix-preparer). Using
        # Lutris instead until upstream nix-gaming fixes it.
        # self.modules.nixos.starcitizen
  ```
- `new_string`:
  ```
        # disabled: nix-gaming dxvk strictDeps/structuredAttrs regression breaks
        # rsi-launcher eval (cross-spliced through wineprefix-preparer).
        # starcitizen-lite below provides the LUG prereqs without the broken
        # launcher path; re-enable this once upstream nix-gaming is fixed.
        # self.modules.nixos.starcitizen
        self.modules.nixos.starcitizen-lite
  ```

- [ ] **Step 2: Build the jezrien system closure**

Run:
```bash
nixos-rebuild build --flake .#jezrien
```

Expected: builds successfully and creates a `result` symlink in the current directory pointing at the new system closure. No activation occurs.

Build time is dominated by whether `gameglass` and `wine-astral` are cached on the nix-citizen cachix or need building from source. With the substituters configured, expect mostly cache hits.

If build fails:
- **Eval error in starcitizen-lite.nix** — re-check Task 1's contents
- **`pkgs.lug-helper` undefined** — unlikely (verified present in nixpkgs), but if it happens, the user's nixpkgs pin is too old; bump nixpkgs or pull lug-helper from an overlay
- **gameglass / wine-astral build failure** — fallback: drop `wineAstralPkg` and the `home.file.".wine-astral"` line; if gameglass also fails, drop `gameglass` from `home.packages` and the desktop entry too. Update the spec and re-commit.

- [ ] **Step 3: Confirm the new module is in the closure**

Run:
```bash
nix eval --raw .#nixosConfigurations.jezrien.config.boot.kernel.sysctl.\"vm.max_map_count\"
```

Expected output: `16777216`

This confirms starcitizen-lite is actually merged into jezrien's NixOS config and not just sitting unused in the flake.

- [ ] **Step 4: Commit**

```bash
git add modules/hosts/jezrien/default.nix
git commit -m "feat(jezrien): enable starcitizen-lite module

Replaces the disabled starcitizen module on this host with the lite
variant so SC's kernel/limits prereqs are in place when launching via
Lutris. The full starcitizen module stays in the tree, disabled, to be
re-enabled once upstream nix-gaming fixes the dxvk regression."
```

---

### Task 3 (handoff): Apply and smoke-test

This task is for the user to run **after merging the worktree branch back to master**, on their main checkout. It's not part of the agentic implementation loop because:
- It mutates the live system (`switch`)
- The user controls when to apply
- Verification needs the user logged in (PAM nofile limit only takes effect on next login)

The plan ends with the worktree branch built clean. The steps below are documentation for the user.

After merge, on master:

```bash
sudo nixos-rebuild switch --flake .#jezrien
```

After the rebuild succeeds, verify in a **fresh shell session** (or after re-login for PAM limits):

```bash
# sysctl values
sysctl vm.max_map_count    # expect: 16777216
sysctl fs.file-max         # expect: 524288

# nofile limit (requires fresh login)
ulimit -Hn                 # expect: 16777216

# kernel modules
lsmod | grep -E "^(v4l2loopback|snd_aloop|ntsync)"

# udev rules present
ls /etc/udev/rules.d/ | grep -i 'lug\|joystick\|hotas\|virpil' || ls /run/current-system/etc/udev/rules.d/

# opentrack and gameglass on PATH
command -v opentrack
command -v gameglass

# wine-astral linked
ls -ld ~/.wine-astral
```

If `ulimit -Hn` does not show `16777216` after re-login, the `pam_limits` module may not be in the active PAM stack for the login type used — check `/etc/pam.d/login` or `/etc/pam.d/sshd` includes `session required pam_limits.so`. On modern NixOS this is configured by default; flag as a separate investigation if it doesn't take effect.

---

## Out of scope (do not implement)

- Replacing or deleting `modules/gaming/starcitizen.nix` (kept disabled in tree, per spec)
- Removing `inputs.nix-citizen` from `flake.nix` (still consumed)
- Setting Wayland / proton env vars system-wide (per-game in Lutris instead)
- Any `programs.rsi-launcher` configuration
- A `mkEnableOption` toggle on the new module
- Wiring starcitizen-lite into any host other than jezrien
- Applying the configuration to the live system (Task 3 handoff)
