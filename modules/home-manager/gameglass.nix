{ config, lib, pkgs, ... }:
let
  cfg = config.rhx.gameglass;
  # gameglass-appimage = pkgs.fetchurl {
  #   url = "https://download.gameglass.gg/hub/GameGlass.AppImage";
  #   sha256 = "0l402438qi006ajqg47shdiimh6aqhn3mvicpbpp9hmzc1iyxz48";
  # };
  libraries = [ pkgs.libevdev ];
  gameglassLauncher = pkgs.writeShellScriptBin "gameglassLauncher" ''
    LD_LIBRARY_PATH=${
      pkgs.lib.makeLibraryPath libraries
    }:$LD_LIBRARY_PATH ${pkgs.gameglass}/bin/GameGlass
  '';
in {
  options.rhx.gameglass = {
    enable = lib.mkEnableOption "Enable gameglass home-manager module.";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      pkgs.gameglass
      #   pkgs.appimage-run
      (pkgs.makeDesktopItem rec {
        name = "GameGlass";
        exec = "${gameglassLauncher}/bin/gameglassLauncher";
        icon = pkgs.fetchurl {
          url =
            "https://framerusercontent.com/images/QFdmL36qlO2pKYp6pJNRxaWkLg.png";
          sha256 = "sha256-3G03GTIYLcF5OuE9h846mQlNBc2VsXNSQw46hjiE+ho=";
        };
        desktopName = name;
        genericName = "GameGlass Control Panels";
        categories = [ "Utility" ];
      })
    ];
  };
}
