{ config, lib, pkgs, username, ... }:
let cfg = config.roles.gaming;
in {
  options.roles.gaming = { enable = lib.mkEnableOption "Enable gaming role."; };

  config = lib.mkIf cfg.enable {
    gaming = {
      gamemode.enable = true;
      steam.enable = true;
    };
  };
}
