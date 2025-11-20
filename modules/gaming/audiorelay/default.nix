{ config, lib, username, ... }:
let cfg = config.rhx.audiorelay;
in {
  options.rhx.audiorelay = {
    enable = lib.mkEnableOption "Enable audiorelay module.";
  };

  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [ 59100 ];
    networking.firewall.allowedUDPPorts = [ 59100 ];

    home-manager.users.${username}.imports = [ ./home.nix ];
  };
}
