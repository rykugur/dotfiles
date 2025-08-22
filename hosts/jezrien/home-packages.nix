# random dumping-ground; some day I'll clean this up
{ pkgs, ... }: {
  home.packages = with pkgs; [
    ################################# dev #################################
    direnv
    just
    prettierd
    stylua
    vscode

    ################################# nix #################################
    nix-prefetch-scripts

    ################################# fonts? #################################
    font-awesome

    ################################# gaming #################################

    ################################# random #################################
    n0la_rcon
    arandr
    cliphist
    pywal
    wev
    wl-clipboard
    wl-clipboard-x11
    wtype
    xorg.xrandr
    xorg.xbacklight

    nwg-look
    catppuccin-gtk
    catppuccin-cursors
    catppuccin-papirus-folders

    baobab
    bat
    bottom
    fastfetch
    file
    file-roller
    jellyfin-media-player
    # lampray
    mousai
    nemo
    nitch
    nixd
    nix-index
    nvtopPackages.full
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

    wofi
    wofi-emoji

    p7zip
    unzip
    xz
    zip

    dnsutils
    duf
    dysk
    eza
    fzf
    jq
    ldns
    lsof
    lm_sensors
    ncdu
    nmap
    pciutils
    psmisc
    silver-searcher
    speedtest-cli
    tree
    usbutils
    wget

    iotop
    iftop

    libtool
    neovide

    telegram-desktop
  ];
}
