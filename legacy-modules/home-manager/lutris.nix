{
  config,
  osConfig,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.ryk.lutris;
in
{
  options.ryk.lutris = {
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
      winePackages = [ pkgs.wineWow64Packages.stagingFull ];

    };

    # force lutris to use nixpkgs umu-launcher
    home.file = {
      ".local/share/lutris/runtime/umu/umu-run" = {
        source = "${pkgs.umu-launcher}/bin/umu-run";
        force = true;
      };
    };
  };
}
