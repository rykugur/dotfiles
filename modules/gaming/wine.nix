{ config, lib, pkgs, username, ... }:
let cfg = config.modules.gaming.wine;
in {
  options.modules.gaming.wine.enable = lib.mkEnableOption "enable wine";

  config = lib.mkIf cfg.enable {
    home-manager.users.${username} = {
      home.packages = with pkgs; [
        bottles
        protontricks
        protonup-ng
        protonup-qt
        wineWowPackages.waylandFull
        winetricks
      ];
    };
  };
}
