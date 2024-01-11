{ config, inputs, lib, pkgs, ... }: {
  home.packages = with pkgs; [
    cliphist
    dunst
    libnotify
    grim
    inputs.hyprland-contrib.packages.${pkgs.system}.hyprprop
    pywal
    slurp
    swappy
    swayidle
    swaylock
    wl-clipboard
    wlogout
    wofi
    xorg.xrandr
  ];

  programs.waybar = {
    enable = true;
    package = pkgs.waybar.overrideAttrs (oldAttrs: {
      mesonFlags = oldAttrs.mesonFlags ++ [ "-Dexperimental=true" ];
    });
  };

  home.file = {
    ".config/hypr" = {
      source = ../../configs/hypr;
    };
    ".config/waybar" = {
      source = ../../configs/waybar;
      recursive = true;
    };
    ".config/swappy" = {
      source = ../../configs/swappy;
      recursive = true;
    };
  };
}
