{ config, inputs, lib, pkgs, username, ... }:
let cfg = config.roles.gaming;
in {
  options.roles.gaming.enable = lib.mkEnableOption "Enable gaming role.";

  config = lib.mkIf cfg.enable {
    modules.gaming = {
      discord.enable = true;
      gamemode.enable = true;
      steam.enable = true;
      wine.enable = true;
    };

    home-manager.users.${username} = {
      home.packages = [
        inputs.umu.packages.${pkgs.system}.umu

        pkgs.gamescope
        pkgs.lutris
        pkgs.mangohud
        pkgs.unixtools.xxd
        pkgs.xdelta
      ];
    };
  };
}
