{ config, inputs, lib, pkgs, ... }: {
  home.packages = with pkgs; [
    cliphist
    swayidle
    swaylock
    waybar
    wl-clipboard
  ];
  home.file = {
    ".config/hypr" = {
      source = ../../../../configs/hypr;
    };
    ".config/waybar" = {
      source = ../../../../configs/waybar;
      recursive = true;
    };
  };
}
