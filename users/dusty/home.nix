# This is your home-manager configuration file
# Use this to configure your home environment (it replaces ~/.config/nixpkgs/home.nix)
{ inputs, outputs, pkgs, username, ... }:
let
  mo2installer = inputs.nix-gaming.packages.${pkgs.system}.mo2installer;
  umuPkg = inputs.umu.packages.${pkgs.system}.umu.override {
    version = inputs.umu.shortRev;
    truststore = true;
  };
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
  dconf = {
    enable = true;
    settings = {
      "org/gnome/mutter" = {
        auto-maximize = false;
        check-alive-timeout = "30000";
      };
      "org/gnome/desktop/interface" = { color-scheme = "prefer-dark"; };
      "org/gnome/desktop/wm/preferences" = {
        audible-bell = false;
        visual-bell = false;
      };
      "org/gnome/desktop/peripherals/keyboard" = {
        numlock-state = true;
        remember-numlock-state = true;
      };
    };
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
    # bottles
    dxvk
    gamescope
    lutris
    mangohud
    mo2installer
    protontricks
    protonup-ng
    protonup-qt
    steamcmd
    steam-tui
    # umuPkg
    unixtools.xxd
    vkd3d
    wineWowPackages.waylandFull
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
    lampray
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
    albert.enable = true;
    browser.enable = true;
    discord.enable = true;
    easyeffects.enable = true;
    face-tracking.enable = true;
    fuzzel.enable = true;
    ghostty.enable = true;
    git.enable = true;
    hyprland.enable = true;
    keebs.enable = true;
    kitty.enable = true;
    nushell.enable = true;
    nvim.enable = true;
    obs.enable = true;
    ssh.enable = true;
    #starcitizen.enable = true;
    starsector = {
      enable = true;
      mods.enable = true;
    };
    starship.enable = true;
    swappy.enable = true;
    thunar.enable = true;
    tmux.enable = true;
    zellij.enable = true;
  };

  ################## other stuff you shouldn't need to touch
  programs.home-manager.enable = true;

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "23.11";
}
