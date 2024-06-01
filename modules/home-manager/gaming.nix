{pkgs, ...}: {
  home.packages = [
    pkgs.discord
    pkgs.betterdiscordctl

    pkgs.gamescope
    pkgs.lutris
    pkgs.mangohud

    pkgs.protontricks
    pkgs.protonup-ng
    pkgs.protonup-qt
    pkgs.steamcmd
    pkgs.steam-tui
    pkgs.wineWowPackages.waylandFull
    pkgs.winetricks

    pkgs.n0la_rcon

    pkgs.dxvk
    pkgs.vkd3d
  ];
}
