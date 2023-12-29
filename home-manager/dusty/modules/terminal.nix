{ config, inputs, lib, pkgs, username, ... }: {
  home.packages = [ pkgs.kitty ];

  programs.starship = {
    enable = true;
  };
}
