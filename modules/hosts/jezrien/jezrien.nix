{
  inputs,
  self,
  ...
}:
{
  flake = {
    nixosModules = {
      jezrien-config =
        { config, ... }:
        let
          metaCfg = config.meta.ryk;
        in
        {
          imports = [
            # TODO: refactor these into modules
            ./_configuration.nix

            inputs.stylix.nixosModules.stylix

            self.nixosModules.home-manager

            self.nixosModules.fonts
            self.nixosModules.stylix
            self.nixosModules.audiorelay

            self.nixosModules._3dp
            self.nixosModules.helix
            self.nixosModules.ssh
          ];

          home-manager.users.${metaCfg.username} = {
            imports = [
              self.homeModules.sops
              ./_home-packages.nix
            ];
          };
        };

      jezrien-hardware =
        { ... }:
        {
          imports = [
            ./_hardware-configuration.nix
          ]
          ++ (with inputs.nixos-hardware.nixosModules; [
            common-pc
            common-pc-ssd
            common-cpu-amd
            common-gpu-amd
          ]);
        };
    };
  };
}

# modules to convert:
#
# darwin/
# aerospace.nix
#
# desktop/
# dankMaterialShell/...
# hyprland/...
# mangowc/...
# niri/...
# noctalia/...
# shared.nix
#
# gaming/
# eve-online/...
# jackify/...
# nexus-mods/...
# starcitizen/...
# vr/...
#
# home-manager/
# aerospace.nix
# albert.nix
# atuin.nix
# bat.nix
# browser.nix
# btop.nix
# carapace.nix
# default.nix
# direnv.nix
# discord.nix
# easyeffects.nix
# firefox.nix
# fish.nix
# flameshot.nix
# fuzzel.nix
# ghostty.nix
# git.nix
# gnome.nix
# homelab.nix
# jujutsu.nix
# keebs.nix
# kitty.nix
# lutris.nix
# nautilus.nix
# nemo.nix
# nushell.nix
# nvim.nix
# ranger.nix
# starsector.nix
# starship.nix
# swappy.nix
# swaylock.nix
# thunar.nix
# tmux.nix
# vicinae.nix
# walker.nix
# wezterm.nix
# yazi.nix
# zed-editor.nix
# zellij.nix
# zoxide.nix
#
# misc/
# appimage/...
#
# nixos/
# 1password.nix
# btrfs.nix
# default.nix
# distrobox.nix
# gamemode.nix
# gnome.nix
# kde.nix
# obs-studio.nix
# pipewire.nix
# razer.nix
# steam.nix
# vfio.nix
# virtman.nix
# wooting.nix
# zsa.nix
#
# virtualization/
# docker.nix
# winboat.nix
