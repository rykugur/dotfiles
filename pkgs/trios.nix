{
  lib,
  stdenv,
  fetchzip,
  autoPatchelfHook,
  copyDesktopItems,
  makeDesktopItem,
  makeWrapper,
  atk,
  cairo,
  curl,
  fontconfig,
  gdk-pixbuf,
  glib,
  gtk3,
  jre_headless,
  harfbuzz,
  libGL,
  libepoxy,
  libxkbcommon,
  pango,
}:
let
  pname = "trios";
  version = "1.6.1";

  release =
    {
      x86_64-linux = {
        filename = "TriOS-Linux.zip";
        hash = "sha256-Xt+q86ik8QRxwenjVhGR8WnmWDBOIPY9eDv7HxGFJ5Y=";
      };
      aarch64-darwin = {
        filename = "TriOS-MacOS-AppleSilicon.zip";
        hash = "sha256-yMPshWT2dKllGXPmW3as7WGUKHlJMiY6TDK0KcpsSow=";
      };
    }
    .${stdenv.hostPlatform.system}
      or (throw "TriOS is only available for x86_64-linux and aarch64-darwin");

  src = fetchzip {
    url = "https://github.com/wispborne/TriOS/releases/download/${version}/${release.filename}";
    inherit (release) hash;
  };

  linuxRuntimeDeps = [
    atk
    cairo
    curl
    fontconfig
    gdk-pixbuf
    glib
    gtk3
    jre_headless
    harfbuzz
    libGL
    libepoxy
    libxkbcommon
    pango
  ];

  desktopItem = makeDesktopItem {
    name = "trios";
    desktopName = "TriOS";
    genericName = "Starsector launcher and mod manager";
    comment = "All-in-one Starsector launcher, mod manager, and toolkit";
    exec = "trios";
    icon = "trios";
    categories = [ "Game" ];
    extraConfig = {
      Categories = "Game;";
    };
  };
in
stdenv.mkDerivation {
  inherit pname version src;

  nativeBuildInputs = [ makeWrapper copyDesktopItems ] ++ lib.optionals stdenv.hostPlatform.isLinux [ autoPatchelfHook ];
  buildInputs = lib.optionals stdenv.hostPlatform.isLinux linuxRuntimeDeps;
  desktopItems = lib.optionals stdenv.hostPlatform.isLinux [ desktopItem ];
  preFixup = lib.optionalString stdenv.hostPlatform.isLinux ''
    addAutoPatchelfSearchPath ${jre_headless}/lib/openjdk/lib/server
  '';

  dontConfigure = true;
  dontBuild = true;

  installPhase =
    if stdenv.hostPlatform.isLinux then
      ''
        install -Dm755 TriOS $out/libexec/trios/TriOS
        cp -r lib data $out/libexec/trios/
        install -Dm644 \
          data/flutter_assets/assets/images/telos_faction_crest.png \
          $out/share/icons/hicolor/128x128/apps/trios.png
        chmod +x $out/libexec/trios/data/flutter_assets/assets/linux/7zip/x64/7zzs

        makeWrapper $out/libexec/trios/TriOS $out/bin/trios \
          --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath linuxRuntimeDeps}"
        runHook postInstall
      ''
    else
      ''
        mkdir -p $out/Applications/TriOS.app
        cp -r Contents $out/Applications/TriOS.app/

        makeWrapper $out/Applications/TriOS.app/Contents/MacOS/TriOS $out/bin/trios
      '';

  meta = {
    description = "All-in-one Starsector launcher, mod manager, and toolkit";
    homepage = "https://github.com/wispborne/TriOS";
    license = lib.licenses.unfree;
    mainProgram = "trios";
    platforms = [ "x86_64-linux" "aarch64-darwin" ];
  };
}
