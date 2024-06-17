{ config, lib, pkgs, ... }:
let cfg = config.modules.gaming.gamemode;
in {
  options.modules.gaming.gamemode.enable = lib.mkEnableOption "Enable Gamemode";

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
