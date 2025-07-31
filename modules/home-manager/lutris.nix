{ config, osConfig, lib, pkgs, ... }:
let cfg = config.rhx.lutris;
in {
  options.rhx.lutris = {
    enable = lib.mkEnableOption "Enable lutris home-manager module.";
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [ umu-launcher ];

    programs.lutris = {
      enable = true;

      extraPackages = with pkgs; [
        mangohud
        winetricks
        gamescope
        gamemode
        umu-launcher
        wmctrl
      ];

      steamPackage = osConfig.programs.steam.package;
      protonPackages = [ pkgs.proton-ge-bin ];
      winePackages = [ pkgs.wineWowPackages.stagingFull ];
    };
  };
}
