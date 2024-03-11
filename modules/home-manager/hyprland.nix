{ inputs, outputs, pkgs, ... }: {
  imports = [
    outputs.homeManagerModules.wayland
  ];

  home.packages = with pkgs; [
    dunst
    libnotify
    grim
    grimblast
    hyprlock
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
}
