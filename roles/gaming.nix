{ config, inputs, lib, pkgs, username, ... }:
let
  cfg = config.ryk.roles.gaming;
  mo2installer =
    inputs.nix-gaming.packages.${pkgs.stdenv.hostPlatform.system}.mo2installer;
in {
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
      ryk = {
        discord.enable = true;
        lutris.enable = true;
      };

      home.packages = with pkgs; [
        steamcmd

        protonup-ng
        protonup-qt
        winetricks

        # misc
        bottles
        dxvk
        gamescope
        heroic
        mangohud
        mo2installer
        moonlight-qt
        unixtools.xxd
        vkd3d
        xdelta
      ];
    };
  };
}
