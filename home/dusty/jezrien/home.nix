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
    base
    browser
    fish
    gaming
    git
    hyprland
    kitty
    nvidia
    nvim
    obs
    terminal
    theme

    star-citizen
    starsector
  ];

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
    username = "dusty";
    homeDirectory = "/home/dusty";

    file = {
      ".config/hypr" = {
        source = ./hypr;
      };
      ".config/waybar/config.json" = {
        source = ./waybar.json;
      };
      ".config/waybar/style.css" = {
        source = ../../../configs/waybar/style.css;
      };
      ".config/waybar/themes" = {
        source = ../../../configs/waybar/themes;
        recursive = true;
      };
      ".config/waybar/launch.fish" = {
        source = ../../../configs/waybar/launch.fish;
        executable = true;
      };
      ".config/swappy" = {
        source = ../../../configs/swappy;
        recursive = true;
      };
    };
  };

  # Add stuff for your user as you see fit:
  # programs.neovim.enable = true;
  home.packages = with pkgs; [
    baobab
    cinnamon.nemo
    gnome.seahorse
    lampray
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
  ];

  ################## other stuff you shouldn't need to touch
  programs.home-manager.enable = true;

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "23.11";
}
