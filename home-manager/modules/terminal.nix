{ config, inputs, lib, pkgs, ... }: {
  home.packages = [ pkgs.kitty ];

  programs.starship = {
    enable = true;
  };
}
