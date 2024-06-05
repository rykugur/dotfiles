# This is your home-manager configuration file
# Use this to configure your home environment (it replaces ~/.config/nixpkgs/home.nix)
{
  outputs,
  pkgs,
  username,
  ...
}: {
  nixpkgs = {
    # You can add overlays here
    overlays = [
      outputs.overlays.additions
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
      permittedInsecurePackages = [
        "electron-25.9.0"
      ];
    };
  };

  home = {
    inherit username;
    homeDirectory = "/home/${username}";
  };

  home.packages = with pkgs; [
    baobab
    bottom
    cinnamon.nemo
    easyeffects
    file
    gnome.seahorse
    gnome.zenity
    google-chrome
    lampray
    mousai
    neofetch
    nitch
    obsidian
    opera
    pavucontrol
    playerctl
    radeontop
    solaar
    speedtest-cli
    spotify
    vlc
    xdg-utils
    xfce.thunar

    prettierd
    stylua

    p7zip
    unzip
    xz
    zip

    dnsutils
    ldns
    nmap
    psmisc
    wget

    vscode

    font-awesome

    # TODO: find a place for these VVV
    discord
    betterdiscordctl
    gamescope
    lutris
    mangohud
    protontricks
    protonup-ng
    protonup-qt
    steamcmd
    steam-tui
    wineWowPackages.waylandFull
    winetricks
    n0la_rcon
    dxvk
    vkd3d
    # TODO: and these VVV
    duf
    eza
    fzf
    grc
    jq
    kitty
    lm_sensors
    pciutils
    ripgrep
    silver-searcher
    tree
    usbutils
    warp-terminal
    zoxide
    btop
    iotop
    iftop
    # TODO: and these VVV
    fira
    (nerdfonts.override {fonts = ["FiraCode" "FiraMono"];})

    catppuccin-gtk
    matcha-gtk-theme
    papirus-icon-theme
    volantes-cursors
    # TODO: and these VVV
    cliphist
    pywal
    wev
    wl-clipboard
    wl-clipboard-x11
    wofi
    wofi-emoji
    wtype
    xorg.xrandr
    xorg.xbacklight
  ];

  # TODO: find a spot for this VVV
  home.pointerCursor = {
    gtk.enable = true;
    name = "Bibata-Modern-Ice";
    package = pkgs.bibata-cursors;
    size = 16;
  };

  # TODO: find a spot for this VVV
  gtk = {
    enable = true;

    font.name = "FiraCode Nerd Font Mono 10";

    theme = {
      name = "Catppuccin-Mocha-Compact-Blue-Dark";
      package = pkgs.catppuccin-gtk.override {
        accents = ["blue"];
        size = "compact";
        tweaks = ["rimless"];
        variant = "mocha";
      };
    };

    cursorTheme = {
      name = "Bibata-Modern-Ice";
      package = pkgs.bibata-cursors;
    };

    iconTheme = {
      name = "Vimix-dark";
      package = pkgs.vimix-icon-theme;
    };

    gtk3.extraConfig = {
      Settings = ''
        gtk-application-prefer-dark-theme=1
      '';
    };

    gtk4.extraConfig = {
      Settings = ''
        gtk-application-prefer-dark-theme=1
      '';
    };
  };

  # nvim.enable = true;
  # obs.enable = true;
  # swappy.enable = true;
  # swayfx.enable = true;

  ################## other stuff you shouldn't need to touch
  programs.home-manager.enable = true;

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "23.11";
}
