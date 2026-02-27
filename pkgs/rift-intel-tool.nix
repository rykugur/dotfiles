{
  pkgs,
  lib,
  fetchurl,
  stdenv,
  makeWrapper,
  autoPatchelfHook,
}:

let
  version = "5.17.9";

  # Libraries needed by the bundled JRE's AWT/Swing
  runtimeLibs = [
    pkgs.libx11
    pkgs.libxext
    pkgs.libxi
    pkgs.libxrender
    pkgs.libxtst
    pkgs.libxcursor
    pkgs.libxrandr
    pkgs.fontconfig
    pkgs.freetype
    pkgs.zlib
    pkgs.alsa-lib
    pkgs.libGL
    pkgs.gtk3
    pkgs.glib
    pkgs.gdk-pixbuf
  ];

in
stdenv.mkDerivation {
  pname = "rift-intel-tool";
  inherit version;

  src = fetchurl {
    url = "https://riftforeve.online/download/rift-${version}-linux-amd64.tar.gz";
    sha256 = "sha256-zYYCfkaUe7DcdHjY/vOlKhsrlBwJYdVp+xU5l6OU124=";
  };

  nativeBuildInputs = [ makeWrapper autoPatchelfHook ];

  buildInputs = [
    pkgs.wmctrl
    pkgs.wayland
    stdenv.cc.cc.lib
  ] ++ runtimeLibs;

  unpackPhase = ''
    tar -xzf $src
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -r rift-${version}/{bin,lib,share} $out/

    substituteInPlace $out/share/applications/*.desktop \
      --replace-fail /usr/lib/nohus/rift/bin/rift $out/bin/rift

    wrapProgram $out/bin/rift \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath runtimeLibs} \
      --prefix PATH : ${lib.makeBinPath [ pkgs.xwininfo pkgs.xprop pkgs.wmctrl ]}

    runHook postInstall
  '';

  meta = with lib; {
    description = "RIFT Intel Fusion Tool – All your EVE Online intel in one place";
    homepage = "https://riftforeve.online/";
    license = licenses.unfree;
    platforms = [ "x86_64-linux" ];
    mainProgram = "rift";
    maintainers = [ ];
  };
}
