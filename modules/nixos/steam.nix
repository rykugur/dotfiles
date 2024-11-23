{ config, lib, pkgs, ... }:
let cfg = config.rhx.steam;
in {
  options.rhx.steam.enable = lib.mkEnableOption "Enable steam nixOS module";

  config = lib.mkIf cfg.enable {
    programs.steam = {
      enable = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
      extraCompatPackages = [ pkgs.proton-ge-bin ];
    };
  };
}
