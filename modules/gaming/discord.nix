{ config, lib, pkgs, username, ... }:
let cfg = config.modules.gaming.discord;
in {
  options.modules.gaming.discord.enable = lib.mkEnableOption "Enable discord";

  config = lib.mkIf cfg.enable {

    home-manager.users.${username} = {
      home.packages = [ pkgs.discord pkgs.betterdiscordctl ];
    };
  };

}
