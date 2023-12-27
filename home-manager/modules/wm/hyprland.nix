{ config, lib, inputs, pkgs, ... }: {
  wayland.windowManager.hyprland = {
    enable = true;
  };

  home.packages = with pkgs; [
    swaylock
    swayidle
    waybar
  ];

  home.file.".config/hypr/hyprland.conf" = {
    source = config.lib.file.mkOutOfStoreSymlink ../../../configs/hypr/hyprland.conf;
  };
  # home.file.".config/hypr" = {
  #   source = config.lib.file.mkOutOfStoreSymlink ../../../configs/hypr;
  #   recursive = true;
  # };
}
