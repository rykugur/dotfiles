# This is your home-manager configuration file
# Use this to configure your home environment (it replaces ~/.config/nixpkgs/home.nix)
{ inputs, outputs, pkgs, username, ... }:
let
  mo2installer = inputs.nix-gaming.packages.${pkgs.system}.mo2installer;
  umuPkg = inputs.umu.packages.${pkgs.system}.umu;
in {
  imports = [ outputs.hmModules ];

  nixpkgs = {
    # You can add overlays here
    overlays = [
      outputs.overlays.additions
      outputs.overlays.modifications
      inputs.hyprpanel.overlay
      # If you want to use overlays exported from other flakes:
      # neovim-nightly-overlay.overlays.default

      # Or define it inline, for example:
      # (final: prev: {
      #   hi = final.hello.overrideAttrs (oldAttrs: {
      #     patches = [ ./change-hello-to-hi.patch ];
      #   });
      # })
    ];
    # Configure your nixpkgs instance
    config = {
      # Disable if you don't want unfree packages
      allowUnfree = true;
      # Workaround for https://github.com/nix-community/home-manager/issues/2942
      allowUnfreePredicate = _: true;
      # workaround for obsidian
      permittedInsecurePackages = [ "electron-25.9.0" ];
    };
  };

  home = {
    inherit username;
    homeDirectory = "/home/${username}";
  };

  gtk = {
    enable = true;

    font.name = "CaskaydiaCove Nerd Font Mono 10";

    theme = {
      name = "Adementary-dark";
      package = pkgs.adementary-theme;
    };

    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.catppuccin-papirus-folders.override {
        flavor = "mocha";
        accent = "blue";
      };
    };

    gtk2.extraConfig = ''
      gtk-application-prefer-dark-theme=1
    '';

    gtk3.extraConfig = { gtk-application-prefer-dark-theme = 1; };

    gtk4.extraConfig = { gtk-application-prefer-dark-theme = 1; };
  };

  home.packages = with pkgs; [
    ################################# dev #################################
    direnv
    prettierd
    stylua
    vscode

    ################################# fonts? #################################
    font-awesome

    ################################# gaming #################################
    bottles
    dxvk
    gamescope
    lutris
    (makeDesktopItem rec {
      name = "Lutris Experimental";
      exec = "LUTRIS_EXPERIMENTAL_FEATURES_ENABLED=1 lutris %U";
      icon = "lutris";
      desktopName = name;
      genericName = "Lutris w/ LUTRIS_EXPERIMENTAL_FEATURES_ENABLED enabled";
      categories = [ "Game" ];
    })
    mangohud
    mo2installer
    protontricks
    protonup-ng
    protonup-qt
    steamcmd
    steam-tui
    umuPkg
    unixtools.xxd
    vkd3d
    wineWowPackages.stagingFull
    winetricks
    xdelta

    ################################# random #################################
    # super-slicer-latest
    n0la_rcon
    warp-terminal
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
    easyeffects
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
    # mikrotik router mgmt app .
    (winbox.override { wine = wineWowPackages.waylandFull; })
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
    eza
    fzf
    jq
    ldns
    lsof
    lm_sensors
    nmap
    pciutils
    psmisc
    silver-searcher
    speedtest-cli
    tree
    usbutils
    wget

    btop
    iotop
    iftop

    libtool
    neovide

    telegram-desktop
  ];

  rhx = {
    keebs.enable = true;
    starsector = {
      enable = true;
      mods.enable = true;
    };
    swappy.enable = true;
  };

  ################## other stuff you shouldn't need to touch
  programs.home-manager.enable = true;

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "23.11";
}
