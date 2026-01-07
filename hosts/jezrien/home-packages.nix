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
    fd
    file
    file-roller
    # jellyfin-media-player - it or a depdendency uses insecure qtwebengine
    # so just using a chrome PWA for now
    minder
    mousai
    nemo
    nitch
    obsidian
    pavucontrol
    playerctl
    seahorse
    spotify
    sshfs
    tigervnc
    tldr
    vlc
    xdg-utils
    zenity

    amdgpu_top
    radeontop

    feh
    xfce.ristretto

    libtool

    telegram-desktop
  ];
}
