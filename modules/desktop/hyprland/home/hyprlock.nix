{ config, lib, pkgs, ... }:
let cfg = config.rhx.hyprland.hyprlock;
in {
  config = lib.mkIf cfg.enable {
    programs.hyprlock = {
      enable = true;
      settings = {
        source = [
          "${pkgs.catppuccin-ports.hyprlock}/hyprlock.conf"
          "${pkgs.catppuccin-ports.hyprland}/themes/mocha.conf"
        ];
      };
    };

    home.file = {
      # need this file since the catppuccin port references $HOME
      # and I don't care enough to patch it
      ".config/hypr/mocha.conf".source =
        "${pkgs.catppuccin-ports.hyprland}/themes/mocha.conf";
    };
  };
}
