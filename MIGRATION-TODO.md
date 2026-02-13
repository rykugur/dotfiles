# Jezrien Migration TODO

Comparison of old `hosts/jezrien/` config (master branch) vs new
`modules/hosts/jezrien/` config (refactor-flake-parts branch).

## NixOS Modules

All ported:

- [x] `self.nixosModules.zsa` - keyboard vendor
- [x] `self.nixosModules.btrfs`
- [x] `self.nixosModules.pipewire` - with `ryk.pipewire.quantum = 256`
- [x] `self.nixosModules.razer`
- [x] `self.nixosModules.eve-online`
- [x] `self.nixosModules.jackify`
- [x] `self.nixosModules.nexus-mods`
- [x] `self.nixosModules.star-citizen`
- [x] `self.nixosModules.appimage`
- [x] `self.nixosModules.winboat`
- [x] `self.nixosModules._3dp`
- [x] `self.nixosModules.stylix`
- [x] `self.nixosModules.niri`
- [x] `self.nixosModules.dank-material-shell`

## Home-Manager Modules

- [x] `self.nixosModules.keebs`
- [x] `self.nixosModules.ghostty` - with `ryk.ghostty.hideWindowDecoration = true`
- [x] `self.nixosModules.swappy`
- [x] `self.nixosModules.starsector` - commented out for now

**Note:** `btop` is NOT in jezrien imports - only `bat` is. Add if needed.

## Packages

- [x] `kalker` - added to new config
- [x] `google-chrome` - added to new config
- [x] `beyond-all-reason` - intentionally left out
- [x] catppuccin packages - commented out (handled by stylix)

## Resolved

- [x] `ryk.roles.desktop.enable` - was: hyprland, niri, dankMaterialShell, noctalia → niri + dank-material-shell ported
- [x] `ryk.roles.gaming.enable` - was: audiorelay, jackify, nexus-mods, eve-online, starcitizen → all ported
- [x] `stylix.cursors` config (was: phinger-cursors-dark, size 32)
- [x] `ryk.dev.enable` - only enabled `yaak` module

## Still To Do

- [ ] Add `self.nixosModules.btop` if needed (currently missing from imports)
- [ ] Verify `ryk.dankMaterialShell.screenshotBackend = "swappy"` is configured

## Already Ported

- `_3dp`, `helix`, `ssh`, `niri`, `dank-material-shell`, `stylix`, `fonts`, `sops`
- Plus many more added: `1password`, `atuin`, `bat`, `carapace`, `direnv`, `ghostty`,
  `homelab`, `git`, `jackify`, `jujutsu`, `keebs`, `nushell`, `pipewire`, `razer`,
  `starship`, `swappy`, `winboat`, `yazi`, `zellij`, `zen-browser`, `zoxide`, `zsa`,
  `discord`, `gamemode`, `lutris`, `nexus-mods`, `obs-studio`, `steam`, `eve-online`,
  `star-citizen`
