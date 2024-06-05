{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.gaming.steam;
in {
  options = {
    gaming.steam.enable = lib.mkEnableOption "Enable Steam";
  };

  config = lib.mkIf cfg.enable {
    programs.steam = {
      enable = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
      extraCompatPackages = [
        pkgs.proton-ge-bin
      ];
    };
  };
}
