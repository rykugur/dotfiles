# Legacy Module Final Migration Design

**Date:** 2026-04-05
**Scope:** Convert all remaining legacy modules to dendritic pattern, except `legacy-modules/desktop/` (deferred)

## Context

The repo has been mid-migration from legacy modules (`options.ryk.<name>.enable` + `mkIf`) to dendritic flake-parts modules (`flake.modules.<class>.<name>`, opt-in by import). Only `jezrien` still imports `legacy-modules/`. This spec covers converting the remaining non-desktop legacy modules and removing the legacy import from jezrien.

## Approach

**Flat conversion, one module per file.** Each legacy module becomes a single `.nix` file under `modules/` in the appropriate category. All `mkEnableOption`/`mkIf` wrappers are stripped — opt-in is by importing the module. Modules with both NixOS and home-manager config co-locate both in one file (nixos side imports HM side via `self.modules.homeManager.<name>`).

## Module Mapping

| Legacy Module | New Location | Type | Notes |
|---|---|---|---|
| `nixos/1password.nix` | `modules/nixos/1password.nix` | nixos | |
| `nixos/btrfs.nix` | `modules/nixos/btrfs.nix` | nixos | |
| `nixos/distrobox.nix` | `modules/misc/distrobox.nix` | nixos + homeManager | |
| `nixos/gamemode.nix` | `modules/gaming/gamemode.nix` | nixos | |
| `nixos/kde.nix` | `modules/desktop/kde.nix` | nixos | |
| `nixos/obs-studio.nix` | `modules/nixos/obs-studio.nix` | nixos | |
| `nixos/razer.nix` | `modules/nixos/razer.nix` | nixos | |
| `nixos/steam.nix` | `modules/gaming/steam.nix` | nixos | |
| `nixos/vfio.nix` | `modules/virtualization/vfio.nix` | nixos | Keeps `mkOption` for PCI IDs at `options.ryk.vfio.ids` (list of strings, parameterized per-host) |
| `nixos/virtman.nix` | `modules/virtualization/virtman.nix` | nixos | |
| `nixos/wooting.nix` | `modules/nixos/wooting.nix` | nixos | Converted but unimported |
| `nixos/zsa.nix` | `modules/nixos/zsa.nix` | nixos | |
| `gaming/audiorelay/` | `modules/gaming/audiorelay.nix` | nixos + homeManager | Firewall rules + package |
| `gaming/jackify/` | `modules/gaming/jackify.nix` | homeManager | Package only |
| `gaming/nexus-mods/` | `modules/gaming/nexus-mods.nix` | homeManager | Package + mime handler |
| `gaming/vr/` | `modules/gaming/vr.nix` | nixos | Converted but unimported (future use) |
| `misc/appimage/` | `modules/misc/appimage.nix` | nixos | |
| `virtualization/docker.nix` | `modules/virtualization/docker.nix` | nixos | Fix hardcoded `"dusty"` to use `username` arg |
| `virtualization/winboat.nix` | `modules/virtualization/winboat.nix` | nixos + homeManager | No longer force-enables docker; host imports both |

## Conversion Pattern

Modules follow the existing dendritic patterns:

- **nixos-only:** `flake.modules.nixos.<name> = { ... }: { <config> };`
- **homeManager-only:** `flake.modules.homeManager.<name> = { pkgs, ... }: { <config> };`
- **Co-located:** Both in one file; nixos side uses `home-manager.users.${username}.imports = [ self.modules.homeManager.<name> ];`
- **`username`** comes from the `username` specialArg (existing pattern from `ssh.nix`)
- **No `mkEnableOption` / `mkIf`** — the only exception is `vfio.nix` which keeps `mkOption` for `vfioIds` since that's parameterized data, not a toggle

## Deletions

- `legacy-modules/dev/default.nix` — stub with no config body, no-op
- All `default.nix` aggregator files in legacy-modules (not needed in dendritic world)
- `legacy-modules/nixos/default.nix` — contains `keyboardVendor` meta-option; replaced by direct module imports

## Host Integration: jezrien

### `default.nix` changes

**Remove:**
```nix
../../../legacy-modules/nixos
../../../legacy-modules
```

**Add to nixos modules list:**
```nix
self.modules.nixos._1password
self.modules.nixos.btrfs
self.modules.nixos.zsa
self.modules.nixos.razer
self.modules.nixos.obs-studio
self.modules.nixos.gamemode
self.modules.nixos.steam
self.modules.nixos.appimage
```

**Add to homeManager imports list:**
```nix
jackify
nexus-mods
```

### `_configuration.nix` changes

**Remove from `ryk` block:**
- `keyboardVendor` — zsa module imported directly
- `_1password.enable`
- `gamemode.enable`
- `obs-studio.enable`
- `steam.enable`
- `btrfs.enable`
- `razer.enable`
- `dev.enable`
- `gaming.jackify.enable`
- `gaming.nexus-mods.enable`
- `misc.appimage.enable`
- `virtualization.winboat.enable`

**Keep in `ryk` block:**
- `dankMaterialShell.screenshotBackend = "swappy"` — desktop module, out of scope
- `pipewire.quantum = 256` — already dendritic

**Remaining `ryk` block:**
```nix
ryk = {
  dankMaterialShell.screenshotBackend = "swappy";
  pipewire.quantum = 256;
};
```

## Not imported (converted but available for future use)

audiorelay, distrobox, docker, kde, vfio, virtman, vr, winboat, wooting

## Out of scope

- `legacy-modules/desktop/` (hyprland, niri, dankMaterialShell, noctalia) — deferred, user will design separately
- `username` specialArg to config option refactor — separate follow-up
- Pipewire `ryk.pipewire` option namespace — already dendritic, not a legacy module
