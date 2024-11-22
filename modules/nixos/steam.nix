{ config, lib, pkgs, ... }:
let cfg = config.rhx.gamemode;
in {
  options.rhx.gamemode.enable =
    lib.mkEnableOption "Enable gamemode nixOS module";

  config = lib.mkIf cfg.enable {
    programs.steam = {
      enable = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
      extraCompatPackages = [ pkgs.proton-ge-bin ];
    };
  };
}
