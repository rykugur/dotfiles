{ config, inputs, lib, pkgs, hostname, ... }:
let
  cfg = config.rhx.hyprland;
  binds = import ./binds.nix;
  rules = import ./rules.nix;
  defaultSettings = import ./default-settings.nix;
in {
  options.rhx.hyprland = {
    enable = lib.mkEnableOption "Enable hyprland home-manager module.";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      inputs.hyprland-contrib.packages.${pkgs.system}.hyprprop
      # inputs.mcmojave-hyprcursor.packages.${pkgs.system}.default
    ] ++ (with pkgs; [
      dunst
      libnotify
      grim
      grimblast
      hyprcursor
      hypridle
      hyprlock
      hyprpaper
      slurp
      swappy
      wlogout
    ]);

    wayland.windowManager.hyprland =
      let perHostConfig = import ../../../hosts/${hostname}/hyprland-hm.nix;
      in {
        enable = true;

        settings = perHostConfig // defaultSettings // rules // binds;

        # extraConfig = ''
        #   source = ~/.dotfiles/configs/hypr/default.conf
        #   source = ~/.dotfiles/hosts/${hostname}/hyprland.conf
        #   source = ~/.dotfiles/configs/hypr/binds.conf
        #   source = ~/.dotfiles/configs/hypr/input.conf
        #   source = ~/.dotfiles/configs/hypr/rules.conf
        # '';
      };

    home.pointerCursor = {
      name = "phinger-cursors-dark";
      package = pkgs.phinger-cursors;
      size = 32;
      gtk.enable = true;
    };
  };
}
