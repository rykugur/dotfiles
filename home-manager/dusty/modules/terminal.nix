{ config, inputs, lib, pkgs, username, ... }: {
  home.packages = [ pkgs.kitty ];

  programs.starship = {
    enable = true;
  };

  home.file.".config/fish/config.fish" = {
    source = ../../../configs/fish/config.fish;
    force = true;
  };
}
