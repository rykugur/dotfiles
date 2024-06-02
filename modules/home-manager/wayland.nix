{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.wayland;
in {
  options = {
    wayland.enable = lib.mkEnableOption "Enable wayland";
  };
  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      cliphist
      pywal
      wev
      wl-clipboard
      wl-clipboard-x11
      wofi
      wofi-emoji
      wtype
      xorg.xrandr
      xorg.xbacklight
    ];
  };
}
