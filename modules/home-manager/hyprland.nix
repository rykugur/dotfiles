{ config, inputs, lib, pkgs, hostname, ... }: {
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
    xorg.xbacklight
  ];

  programs.waybar = {
    enable = true;
    package = pkgs.waybar.overrideAttrs (oldAttrs: {
      mesonFlags = oldAttrs.mesonFlags ++ [ "-Dexperimental=true" ];
    });
  };
}
