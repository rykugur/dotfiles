{ config, lib, pkgs, username, ... }:
let cfg = config.modules.gaming.steam;
in {
  options.modules.gaming.steam.enable = lib.mkEnableOption "Enable Steam";

  config = lib.mkIf cfg.enable {
    programs.steam = {
      enable = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
      extraCompatPackages = [ pkgs.proton-ge-bin ];
    };

    home-manager.users.${username} = {
      home.packages = with pkgs; [ steamcmd steam-tui ];
    };
  };
}
