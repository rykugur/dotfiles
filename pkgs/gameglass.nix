{ appimageTools, fetchurl, pkgs }:
appimageTools.wrapType2 rec {
  name = "GameGlass";
  pname = name;
  version = "6.9.0";
  src = fetchurl {
    url = "https://download.gameglass.gg/hub/GameGlass.AppImage";
    # TODO: this will fail if they change the AppImage file
    sha256 = "0l402438qi006ajqg47shdiimh6aqhn3mvicpbpp9hmzc1iyxz48";
  };
}
