{ config, lib, pkgs, ... }:
let cfg = config.ryk.gamemode;
in {
  options.ryk.gamemode.enable =
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
