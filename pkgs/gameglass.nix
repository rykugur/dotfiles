{ appimageTools, fetchurl }:
appimageTools.wrapType2 rec {
  name = "GameGlass";
  pname = name;
  version = "6.9.0";
  src = fetchurl {
    url = "https://download.gameglass.gg/hub/GameGlass.AppImage";
    # TODO: this will fail if they change the AppImage file
    sha256 = "sha256-V0dHp2+IeiR1yy7cYsJQV/Zx1BGYOrZXjcTvQ5jaw30=";
  };
}
