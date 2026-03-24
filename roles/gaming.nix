{
  config,
  lib,
  pkgs,
  username,
  outputs,
  ...
}:
let
  cfg = config.ryk.roles.gaming;
in
{
  options.ryk.roles.gaming.enable = lib.mkEnableOption "Enable gaming role";

  config = lib.mkIf cfg.enable {
    # enable nixOS modules for desktop role
    ryk = {
      gamemode.enable = true;
      obs-studio.enable = true;
      steam.enable = true;
    };

    # home-manager config
    home-manager.users.${username} = {
      imports = with outputs.modules.homeManager; [
        discord
        lutris
      ];

      home.packages = with pkgs; [
        steamcmd

        protonplus
        protonup-ng
        protonup-qt
        winetricks

        # misc
        bottles
        dxvk
        gamescope
        heroic
        mangohud
        moonlight-qt
        unixtools.xxd
        vkd3d
        xdelta
      ];
    };
  };
}
