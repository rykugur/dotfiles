{ pkgs, lib, fetchurl, stdenv, makeDesktopItem, makeWrapper }:

let
  version = "5.14.2";

  desktopItem = makeDesktopItem {
    name = "rift";
    exec = "rift";
    comment = "EVE Online Intel Fusion Tool";
    desktopName = "RIFT Intel Tool";
    categories = [ "Game" "Utility" ];
    icon = "rift"; # We'll copy an icon below if available
    startupNotify = true;
  };

  # List of libraries needed by the bundled JRE's AWT/Swing
  x11Libs = [
    pkgs.libx11
    pkgs.libxext
    pkgs.libxi
    pkgs.libxrender
    pkgs.libxtst
    pkgs.libxcursor
    pkgs.libxrandr
    pkgs.fontconfig
    pkgs.freetype
  ];

in stdenv.mkDerivation rec {
  pname = "rift-intel-tool";
  inherit version;

  src = fetchurl {
    url =
      "https://riftforeve.online/download/rift-${version}-linux-amd64.tar.gz";
    sha256 = "sha256-WnsulQ3Drl6tYvOK8MkPDgM4aEIctWyEe1xQ3CfGL0g=";
  };

  nativeBuildInputs = [ makeWrapper ];

  buildInputs = [ pkgs.wmctrl ] ++ x11Libs;

  unpackPhase = ''
    tar -xzf $src
  '';

  installPhase = ''
    runHook preInstall

    mkdir $out
    cp -r rift-${version}/lib $out
    cp -r rift-${version}/share $out

    # Wrapper for the launcher
    mkdir -p $out/bin
    makeWrapper rift-${version}/bin/rift $out/bin/rift \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath x11Libs}

    # Desktop entry
    mkdir -p $out/share/applications
    cp ${desktopItem}/share/applications/* $out/share/applications/

    runHook postInstall
  '';

  meta = with lib; {
    description =
      "RIFT Intel Fusion Tool – All your EVE Online intel in one place";
    homepage = "https://riftforeve.online/";
    license = licenses.unfree;
    platforms = platforms.linux;
    maintainers = [ ];
  };
}
