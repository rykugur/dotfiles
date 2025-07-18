{ appimageTools, fetchurl }:
appimageTools.wrapType2 rec {
  name = "GameGlass";
  pname = name;
  version = "6.9.0";
  src = fetchurl {
    url = "https://download.gameglass.gg/hub/GameGlass.AppImage";
    # TODO: this will fail if they change the AppImage file
    sha256 = "sha256-RhKwB3WtRVoTc9jxTmkQc4qdtj9D9ho84u5oJYwKnpA=";
  };
}
