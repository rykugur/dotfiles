{ config, inputs, lib, pkgs, ... }: {
  home.packages = with pkgs; [
    cliphist
    dunst
    libnotify
    grim
    (pkgs.callPackage ../../derivations/hyprprop.nix { })
    pywal
    slurp
    swappy
    swayidle
    swaylock
    (waybar.overrideAttrs (oldAttrs: {
      mesonFlags = oldAttrs.mesonFlags ++ [ "-Dexperimental=true" ];
    }))
    wl-clipboard
    wlogout
    wofi
    xorg.xrandr
  ];

  home.file = {
    ".config/hypr" = {
      source = ../../../../configs/hypr;
    };
    ".config/waybar" = {
      source = ../../../../configs/waybar;
      recursive = true;
    };
    ".config/swappy" = {
      source = ../../../../configs/swappy;
      recursive = true;
    };
  };
}
