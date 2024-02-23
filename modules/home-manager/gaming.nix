{ pkgs, ... }: {
  home.packages = [
    pkgs.discord
    pkgs.betterdiscordctl

    pkgs.gamemode
    pkgs.lutris

    pkgs.gamescope
    pkgs.steamcmd
    pkgs.steam-tui

    pkgs.protontricks
    pkgs.protonup-ng
    pkgs.protonup-qt

    pkgs.wineWowPackages.waylandFull
    pkgs.winetricks
  ];
}
