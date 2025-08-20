{ config, lib, pkgs, ... }: {
  config = lib.mkIf config.rhx.hyprland.enable {
    programs.hyprlock = {
      enable = true;
      settings = {
        source = [
          "${pkgs.catppuccin-hyprlock}/hyprlock.conf"
          "${pkgs.catppuccin-hyprland}/themes/mocha.conf"
        ];
      };
    };
  };
}
