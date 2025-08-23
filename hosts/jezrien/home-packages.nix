# random dumping-ground; some day I'll clean this up
{ pkgs, ... }: {
  home.packages = with pkgs; [
    ################################# nix #################################
    nix-prefetch-scripts
    nixd
    nix-index

    ################################# fonts? #################################
    font-awesome

    ################################# random #################################
    arandr
    cliphist
    xorg.xrandr
    xorg.xbacklight

    nwg-look
    catppuccin-gtk
    catppuccin-cursors
    catppuccin-papirus-folders

    baobab
    bottom
    fastfetch
    file
    file-roller
    jellyfin-media-player
    mousai
    nemo
    nitch
    obsidian
    pavucontrol
    playerctl
    radeontop
    seahorse
    solaar
    spotify
    sshfs
    tigervnc
    tldr
    vlc
    xdg-utils
    zenity

    feh
    xfce.ristretto

    libtool

    telegram-desktop
  ];
}
