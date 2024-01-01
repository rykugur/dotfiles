{ config, inputs, lib, pkgs, ... }: {
  home.packages = with pkgs; [
    babelfish
    duf
    eza
    fzf
    jq
    kitty
    lm_sensors
    pciutils
    ripgrep
    silver-searcher
    tree
    usbutils

    btop
    iotop
    iftop
    nvtop
  ];

  programs.starship = {
    enable = true;
  };

  programs.fish.plugins = with pkgs.fishPlugins; [
    fzf-fish
    grc
    z
  ];

  home.file = {
    ".config/fish/config.fish" = {
      source = ../../../configs/fish/config.fish;
    };
    ".config/fish/fish_plugins" = {
      source = ../../../configs/fish/fish_plugins;
    };
    ".config/kitty" = {
      source = ../../../configs/kitty;
      recursive = true;
    };
  };
}
