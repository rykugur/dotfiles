{ config, lib, username, ... }:
let cfg = config.ryk.gaming.audiorelay;
in {
  options.ryk.gaming.audiorelay = {
    enable = lib.mkEnableOption "Enable audiorelay module.";
  };

  config = lib.mkIf cfg.enable {
    networking.firewall = {
      allowedTCPPorts = [ 59100 ];
      allowedUDPPorts = [ 59100 ];
    };

    home-manager.users.${username}.imports = [ ./home.nix ];
  };
}
