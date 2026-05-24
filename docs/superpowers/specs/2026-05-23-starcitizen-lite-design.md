# starcitizen-lite

A NixOS + home-manager module that prepares the system for Star Citizen per the LUG Wiki, without bringing in the (currently broken) `programs.rsi-launcher` path from nix-citizen. Game install and launch are left to Lutris.

## Background

`modules/gaming/starcitizen.nix` imports `inputs.nix-citizen.nixosModules.StarCitizen` and configures `programs.rsi-launcher`. As of commit `efbcd838` it is disabled on jezrien because a nix-gaming dxvk `strictDeps` / `structuredAttrs` regression breaks eval of `rsi-launcher` (cross-spliced through `wineprefix-preparer`). The module file stays in the tree, commented out at the host level, until upstream fixes the regression.

In the meantime the system needs the LUG-required kernel/limits tweaks so SC actually runs when launched via Lutris. The LUG Wiki ([Quick Start](https://wiki.starcitizen-lug.org/Quick-Start-Guide), [Alternative Installations](https://wiki.starcitizen-lug.org/Alternative-Installations)) defines the system floor as:

- `vm.max_map_count ≥ 1048576`
- hard `nofile ≥ 524288`
- wine ≥ 9.4 / winetricks ≥ 20250102 (Lutris already provides these via `wineWow64Packages.stagingFull`)

This module gives us that floor plus the joystick/HOTAS, opentrack, and gameglass bits the original module set up, while skipping the broken launcher path.

## Changes

### 1. `modules/gaming/starcitizen-lite.nix` (new)

Dendritic module mirroring the structure of `modules/gaming/starcitizen.nix`. Exposes two flake outputs: `flake.modules.nixos.starcitizen-lite` and `flake.modules.homeManager.starcitizen-lite`. Import-to-enable (no `mkEnableOption`), matching `steam.nix` / `lutris.nix` / `jackify.nix`.

**NixOS-level (`flake.modules.nixos.starcitizen-lite`):**

- LUG prereqs (values match nix-citizen's, which exceed the LUG floor):
  - `boot.kernel.sysctl."vm.max_map_count" = lib.mkOverride 999 16777216`
  - `boot.kernel.sysctl."fs.file-max" = lib.mkOverride 999 524288`
  - `security.pam.loginLimits` sets both `soft` and `hard` `nofile` to `16777216` (Linux requires `soft ≤ hard`; `soft`-only — as nix-citizen does — won't actually let processes raise their nofile above the system default)
- Kernel modules (same set nix-citizen sets up):
  - `boot.extraModulePackages = with config.boot.kernelPackages; [ v4l2loopback ]`
  - `boot.kernelModules = [ "snd-aloop" ] ++ lib.optional (lib.versionAtLeast config.boot.kernelPackages.kernel.version "6.14") "ntsync"`
- udev rules:
  - `services.udev.enable = true`
  - `services.udev.packages = [ pkgs.lug-helper ]` — pulls only the joystick/HOTAS rules from `/etc/udev/rules.d` into the system; the LUG Helper GUI binary stays out of the system closure as long as it isn't also listed in `systemPackages`
  - `services.udev.extraRules` keeps the existing Virpil rule from `starcitizen.nix`:
    ```
    KERNEL=="hidraw*", ATTRS{idVendor}=="3344", ATTRS{idProduct}=="*", MODE="0660", TAG+="uaccess"
    ```
- Substituters (still consuming `gameglass` and `wine-astral` from nix-citizen):
  - `nix.settings.substituters` adds `https://nix-citizen.cachix.org` and `https://nix-gaming.cachix.org`
  - `nix.settings.trusted-public-keys` adds the matching keys
- Wire home-manager: `home-manager.users.${username}.imports = [ self.modules.homeManager.starcitizen-lite ]`, where `username` is read from `config.ryk.username` (same pattern as the old module)

**home-manager-level (`flake.modules.homeManager.starcitizen-lite`):**

- `home.packages = with pkgs; [ opentrack-StarCitizen gameglass ]`
  - `opentrack-StarCitizen` from `pkgs/opentrack-StarCitizen.nix` (already in this repo's overlay)
  - `gameglass` from `inputs.nix-citizen.packages.${pkgs.stdenv.hostPlatform.system}.gameglass`
- `home.file.".wine-astral".source = inputs.nix-citizen.packages.${system}.wine-astral` — the wine prefix opentrack uses to talk to the SC wine instance
- `xdg.desktopEntries.gameglass` — same as the old module: `Name=GameGlass`, `Icon=gameglass`, `Exec=${gameglass}/bin/gameglass`, categories `Game`, `Utility`

### 2. `modules/hosts/jezrien/default.nix` (modify)

- Add `self.modules.nixos.starcitizen-lite` to the imports list (alongside the other `self.modules.nixos.*` entries)
- Update the comment on the disabled `self.modules.nixos.starcitizen` line to point at `starcitizen-lite` as the active replacement until upstream nix-gaming is fixed
- Leave the disabled `starcitizen` line itself in place

## Files touched

| File | Action |
|---|---|
| `modules/gaming/starcitizen-lite.nix` | Create |
| `modules/hosts/jezrien/default.nix` | Add starcitizen-lite import; update comment on disabled starcitizen line |

## Out of scope

- Replacing or deleting `modules/gaming/starcitizen.nix` (kept disabled in tree, per "easy to flip back once nix-citizen is fixed")
- Removing `inputs.nix-citizen` from `flake.nix` (still consumed by both the disabled module and by `gameglass` / `wine-astral`)
- Wayland / proton env vars (`MESA_VK_WSI_PRESENT_MODE`, `DXVK_HUD`, `MANGO_HUD`, `WINE_HIDE_NVIDIA_GPU`, `PROTON_ENABLE_WAYLAND`, `WINEDLLOVERRIDES`) — set per-game in Lutris instead of globally
- Any `programs.rsi-launcher` configuration
- Adding `lug-helper` to user packages as a GUI tool (only its udev rules are consumed)
- A `mkEnableOption` toggle — import-to-enable matches the rest of `modules/gaming/`

## Risks

- `gameglass` and `wine-astral` come from `inputs.nix-citizen.packages.<system>.*`. These are package outputs, separate from the `nixosModules.StarCitizen` eval path that is currently broken. Expected to build cleanly; if a rebuild surfaces a transitive break, the fallback is to drop `wine-astral` from the home config and either standalone-package or drop `gameglass`.
- `lug-helper` is a Bash-GUI tool. `services.udev.packages` only pulls its `/etc/udev/rules.d/*` into the system, but any future change that also adds it to `environment.systemPackages` or `home.packages` would bring the GUI binary along with it.
