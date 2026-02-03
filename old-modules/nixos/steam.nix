{ config, lib, pkgs, ... }:
let cfg = config.ryk.steam;
in {
  options.ryk.steam.enable = lib.mkEnableOption "Enable steam nixOS module";

  config = lib.mkIf cfg.enable {
    programs.steam = {
      enable = true;

      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;

      extraCompatPackages = [ pkgs.proton-ge-bin ];

      protontricks.enable = true;
    };
  };
}
