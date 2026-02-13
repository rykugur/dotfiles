# random dumping-ground; some day I'll clean this up
{ pkgs, ... }:
{
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

    # nwg-look
    # catppuccin-gtk
    # catppuccin-cursors
    # catppuccin-papirus-folders

    baobab
    bottom
    bruno
    claude-code
    fastfetch
    fd
    file
    file-roller
    google-chrome
    # jellyfin-media-player - it or a depdendency uses insecure qtwebengine
    # so just using a chrome PWA for now
    kalker
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
    ristretto

    libtool

    telegram-desktop

    # from roles/gaming.nix
    steamcmd
    protonup-ng
    protonup-qt
    winetricks
    # misc
    bottles
    dxvk
    gamescope
    heroic
    mangohud
    moonlight-qt
    unixtools.xxd
    vkd3d
    xdelta

    # from roles/dev.nix
    just
    prettierd
    stylua
    vscode
    insomnia

    # from roles/terminal.nix
    cmatrix
    dnsutils
    dysk
    fzf
    jq
    iftop
    iotop
    glow
    ldns
    lsof
    lm_sensors
    nmap
    pciutils
    p7zip
    psmisc
    silver-searcher
    speedtest-cli
    tree
    unzip
    usbutils
    wget
    xz
    zip
    duf
    dust
    gdu
  ];
}
