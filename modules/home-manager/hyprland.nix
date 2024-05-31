{ config, inputs, outputs, pkgs, ... }:
let
  host = "taln";
in
{
  imports = [
    outputs.homeManagerModules.wayland
  ];

  home.packages = with pkgs; [
    dunst
    libnotify
    grim
    grimblast
    hyprlock
    hyprpaper
    inputs.hyprland-contrib.packages.${pkgs.system}.hyprprop
    slurp
    swappy
    swayidle
    swaylock
    wlogout
  ];

  programs.waybar = {
    enable = true;
    package = pkgs.waybar.overrideAttrs (oldAttrs: {
      mesonFlags = oldAttrs.mesonFlags ++ [ "-Dexperimental=true" ];
    });
  };

  programs.fuzzel = {
    enable = true;
    settings = {
      colors = {
        background = "1e1e2edd";
        text = "cdd6f4ff";
        match = "f38ba8ff";
        selection = "585b70ff";
        selection-match = "f38ba8ff";
        selection-text = "cdd6f4ff";
        border = "b4befeff";
      };
    };
  };

  home.file = {
    ".config/hypr" = {
      source = ../../configs/hypr;
      recursive = true;
    };
    ".config/hypr/host_custom.conf" = {
      source = ../../home/dusty/${host}/hyprland.conf;
    };
  };
}
