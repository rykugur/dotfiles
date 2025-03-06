{ config, lib, pkgs, username, ... }:
let cfg = config.rhx.roles.gaming;
in {
  options.rhx.roles.gaming.enable = lib.mkEnableOption "Enable gaming role";

  config = lib.mkIf cfg.enable {
    # enable nixOS modules for desktop role
    rhx = {
      gamemode.enable = true;
      steam.enable = true;
    };

    # home-manager config
    home-manager.users.${username} = {
      rhx = {
        discord.enable = true;
        obs.enable = true;
      };

      home.packages = with pkgs; [
        steamcmd

        # for eve
        steamtinkerlaunch
        wmctrl

        # for star citizen
        gameglass
      ];
    };
  };
}
