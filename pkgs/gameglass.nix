{ appimageTools, fetchurl, pkgs }:
# let
# icon = fetchurl {
#   url = "https://framerusercontent.com/images/QFdmL36qlO2pKYp6pJNRxaWkLg.png";
#   sha256 = "sha256-3G03GTIYLcF5OuE9h846mQlNBc2VsXNSQw46hjiE+ho=";
# };
# in
appimageTools.wrapType2 rec {
  name = "GameGlass";
  pname = name;
  version = "6.9.0";
  src = fetchurl {
    url = "https://download.gameglass.gg/hub/GameGlass.AppImage";
    sha256 = "0l402438qi006ajqg47shdiimh6aqhn3mvicpbpp9hmzc1iyxz48";
  };

  # shellHook = ''
  #   export LD_LIBRARY_PATH=${
  #     pkgs.lib.makeLibraryPath [ pkgs.libevdev ]
  #   }:$LD_LIBRARY_PATH
  # '';
  #
  # installPhase = ''
  #   mkdir -p $out/bin
  #   mv * $out/bin
  #
  #   mkdir -p $out/share/applications
  #   echo "[Desktop Entry]
  #   Version=${version}
  #   Icon=${icon}
  #   Exec=$out/bin/GameGlass
  #   Terminal=false
  #   Type=Application
  #   Categories=Game;
  #   Name=GameGlass
  #   Comment=GameGlass Utility" > $out/share/application/GameGlass.desktop
  # '';
}
