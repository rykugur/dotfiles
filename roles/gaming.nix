{ config, inputs, lib, pkgs, username, ... }:
let
  cfg = config.rhx.roles.gaming;
  mo2installer = inputs.nix-gaming.packages.${pkgs.system}.mo2installer;
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
        lutris.enable = true;
        obs.enable = true;
      };

      home.packages = with pkgs; [
        steamcmd

        # for eve
        steamtinkerlaunch
        wmctrl

        # for star citizen
        gameglass

        protontricks
        protonup-ng
        protonup-qt
        winetricks

        # misc
        bottles
        dxvk
        gamescope
        (makeDesktopItem rec {
          name = "Lutris Experimental";
          exec = "LUTRIS_EXPERIMENTAL_FEATURES_ENABLED=1 lutris %U";
          icon = "lutris";
          desktopName = name;
          genericName =
            "Lutris w/ LUTRIS_EXPERIMENTAL_FEATURES_ENABLED enabled";
          categories = [ "Game" ];
        })
        mangohud
        mo2installer
        pyfa
        unixtools.xxd
        vkd3d
        xdelta
      ];
    };
  };
}
