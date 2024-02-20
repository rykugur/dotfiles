{ config, inputs, lib, pkgs, ... }: {
  home.packages = [
    # (pkgs.discord.override {
    #   # fixes links not opening in firefox
    #   nss = pkgs.nss_latest;
    # })
    pkgs.discord
    pkgs.betterdiscordctl

    pkgs.lutris

    pkgs.protontricks
    pkgs.protonup-ng
    pkgs.protonup-qt

    pkgs.prismlauncher
    pkgs.starsector

    # pkgs.wine
    pkgs.wineWowPackages.waylandFull
    # pkgs.wineWowPackages.stable
    pkgs.winetricks
  ];
}
