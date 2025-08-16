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
      obs-studio.enable = true;
      steam.enable = true;
    };

    # home-manager config
    home-manager.users.${username} = {
      rhx = {
        discord.enable = true;
        lutris.enable = true;
      };

      home.packages = with pkgs; [
        steamcmd

        protontricks
        protonup-ng
        protonup-qt
        winetricks

        # misc
        bottles
        dxvk
        gamescope
        mangohud
        mo2installer
        moonlight-qt
        pyfa
        unixtools.xxd
        vkd3d
        xdelta
      ];
    };
  };
}
