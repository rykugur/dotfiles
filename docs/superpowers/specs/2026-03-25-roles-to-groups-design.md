# Roles to Groups: Replacing NixOS-only Roles with Cross-Platform Home-Manager Groups

## Problem

The `roles/` directory provides high-level feature composition (desktop, dev, gaming, terminal, etc.) but has two issues:

1. **Unnecessary indirection** — roles add a layer between modules and hosts that doesn't pull its weight.
2. **NixOS-only** — taln (macOS) can't use roles, so it has a completely separate composition strategy. This means two different ways to do the same thing.

## Design

### New: `modules/groups/`

Replace `roles/` with home-manager group modules in `modules/groups/`. These are standard `flake.modules.homeManager.*` modules auto-discovered by `import-tree` — no `mkEnableOption`, no special machinery. You import them or you don't.

#### `modules/groups/developer.nix`

Merges current `dev` + `terminal` roles (both were already 100% home-manager).

- **Module imports:** git, jujutsu, helix, zed-editor, yaak, atuin, carapace, direnv, starship, ghostty, kitty, bat, yazi, zellij, zoxide
- **Packages:** cmatrix, dnsutils, dysk, fzf, jq, iftop, iotop, glow, ldns, lsof, lm_sensors, nmap, pciutils, p7zip, psmisc, silver-searcher, speedtest-cli, tree, unzip, usbutils, warp-terminal, wget, xz, zip, duf, dust, gdu, bun, just, prettierd, stylua, vscode, bruno, insomnia
- **Platform note:** Linux-only packages (lm_sensors, pciutils, usbutils, iotop, iftop, psmisc) must be gated with `lib.optionals pkgs.stdenv.isLinux`

#### `modules/groups/gaming.nix`

Home-manager portion of current `gaming` role.

- **Module imports:** discord, lutris
- **Packages:** steamcmd, protonplus, protonup-ng, protonup-qt, winetricks, bottles, dxvk, gamescope, heroic, mangohud, moonlight-qt, unixtools.xxd, vkd3d, xdelta

#### No `desktop` group

The current `desktop` role only adds zen-browser and homelab on top of `developer`. This is too thin to justify a group — jezrien imports `developer`, `zen-browser`, and `homelab` directly. SSH home-manager config is imported transitively via the NixOS ssh module (`modules/misc/ssh.nix`).

#### `modules/groups/_3dp.nix`

Unchanged from current `3dp` role.

- **Packages:** qidi-slicer-bin, freecad-wayland

#### `server` role

Dropped with no replacement. Currently an empty stub with no config.

### Host config changes

#### `modules/hosts/jezrien.nix`

Groups are added to the existing home-manager imports block:

```nix
home-manager.users.${username}.imports = with hmModules; [
  developer gaming _3dp
  zen-browser homelab
  # plus existing individual module imports (btop, nushell, etc.)
];
```

The `../../roles` import is removed from the NixOS modules list.

#### NixOS config previously triggered by roles

The following `ryk.*` enables currently happen inside role files and must move to `hosts/jezrien/configuration.nix` directly:

From `desktop` role:
- `ryk._1password.enable = true`
- Import of `outputs.modules.nixos.ssh` (add to `modules/hosts/jezrien.nix` NixOS modules list)

From `gaming` role:
- `ryk.gamemode.enable = true`
- `ryk.obs-studio.enable = true`
- `ryk.steam.enable = true`

The `ryk.roles` block in `hosts/jezrien/configuration.nix` (lines 159-163) must be removed entirely — those option definitions will no longer exist.

#### `modules/hosts/taln.nix`

Taln can now use groups too. Replace individual module imports with the `developer` group plus any taln-specific modules.

### `roles/default.nix` base config

The base NixOS config in `roles/default.nix` (timezone, locale, i18n, nix settings, nix registry/nixPath, overlays, base system packages) moves to a new NixOS module: `modules/base/nix-defaults.nix` exposing `flake.modules.nixos.nix-defaults`.

In `modules/hosts/jezrien.nix`, the `../../roles` import (line 19) is replaced with `self.modules.nixos.nix-defaults`. This single line change handles both removing all roles AND adding the base config module. The overlays are already applied in `hosts/jezrien/home.nix` at the home-manager level; the system-level overlays in `roles/default.nix` are for NixOS system packages and must be preserved in the new module.

### Cleanup

- `eve-online` NixOS wrapper (`flake.modules.nixos.eve-online`) deleted — it just passes through to the home-manager module. Jezrien's import changes from `self.modules.nixos.eve-online` to a home-manager import.
- `roles/` directory deleted entirely.

## Principles

- **Groups are home-manager only** — cross-platform by definition.
- **NixOS modules are imported directly by hosts** — no grouping layer needed for system-level config.
- **No mkEnableOption on groups** — import-based composition, not option-based. Simpler.
- **Same mechanism everywhere** — jezrien and taln both use `outputs.modules.homeManager.*` imports. One pattern, not two.
