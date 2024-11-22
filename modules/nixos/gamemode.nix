{ config, lib, pkgs, ... }:
let cfg = config.rhx.gamemode;
in {
  options.rhx.gamemode.enable =
    lib.mkEnableOption "Enable gamemode nixOS module";

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
