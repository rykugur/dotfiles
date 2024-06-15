{ config, lib, pkgs, ... }:
let cfg = config.gaming.gamemode;
in {
  options.gaming.gamemode.enable = lib.mkEnableOption "Enable Gamemode";

  config = lib.mkIf cfg.enable {
    programs.gamemode = {
      enable = true;
      settings = {
        custom = {
          start = "${pkgs.libnotify}/bin/notify-send 'GameMode started'";
          end = "${pkgs.libnotify}/bin/notify-send 'GameMode ended'";
        };
      };
    };
  };
}
