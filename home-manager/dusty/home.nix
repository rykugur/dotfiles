# This is your home-manager configuration file
# Use this to configure your home environment (it replaces ~/.config/nixpkgs/home.nix)
{ inputs
, outputs
, lib
, config
, pkgs
, ...
}: {
  # You can import other home-manager modules here
  imports = with outputs.homeManagerModules; [
    # If you want to use home-manager modules from other flakes (such as nix-colors):
    # inputs.nix-colors.homeManagerModule
    #
    firefox
    gaming
    git
    hyprland
    nvim
    star-citizen
    terminal
    theme
  ];

  nixpkgs = {
    # You can add overlays here
    overlays = [
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
    username = "dusty";
    homeDirectory = "/home/dusty";
  };

  # Add stuff for your user as you see fit:
  # programs.neovim.enable = true;
  home.packages = with pkgs; [
    baobab
    cinnamon.nemo
    gnome.seahorse
    neofetch
    nitch
    obsidian
    pavucontrol
    solaar
    spotify
    via
    vial
    vlc
    xdg-utils

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

    gcc
    gnumake
    vscode

    font-awesome

    gnome.adwaita-icon-theme
  ];

  ################## other stuff you shouldn't need to touch
  programs.home-manager.enable = true;

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "23.11";
}
