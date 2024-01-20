{ config, inputs, lib, pkgs, ... }: {
  home.packages = [
    (pkgs.discord.override {
      # fixes links not opening in firefox
      nss = pkgs.nss_latest;
    })
    pkgs.betterdiscordctl

    pkgs.lutris

    pkgs.protontricks
    pkgs.protonup-ng
    pkgs.protonup-qt

    pkgs.obs-studio
    pkgs.obs-cli
    pkgs.obs-studio-plugins.input-overlay
    pkgs.obs-studio-plugins.wlrobs

    pkgs.prismlauncher
    pkgs.starsector
  ];
}
