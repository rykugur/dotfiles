{ config, inputs, lib, pkgs, hostname, ... }: {
  home.packages = with pkgs; [
    cliphist
    dunst
    libnotify
    grim
    grimblast
    inputs.hyprland-contrib.packages.${pkgs.system}.hyprprop
    pywal
    slurp
    swappy
    swayidle
    swaylock
    wl-clipboard
    wl-clipboard-x11
    wlogout
    wofi
    wofi-emoji
    wtype
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
