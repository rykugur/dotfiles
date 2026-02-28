{
  lib,
  appimageTools,
  fetchurl,
}:

let
  version = "0.2.0";
  pname = "eve-wrench";

  src = fetchurl {
    url = "https://github.com/eve-wrench/eve-wrench-app/releases/download/v${version}/EVE.Wrench_${version}_amd64.AppImage";
    sha256 = "sha256-G7xDgtUSdY9ntWPlVvKbXVxzFNj5mHSXIq0cjFmkJrw=";
  };

  appimageContents = appimageTools.extractType2 { inherit pname version src; };
in
appimageTools.wrapType2 {
  inherit pname version src;

  extraPkgs = pkgs: [
    pkgs.wayland
    pkgs.libxkbcommon
    pkgs.xdotool
    pkgs.mesa
    pkgs.libGL
    pkgs.libglvnd
  ];

  profile = ''
    export WEBKIT_DISABLE_COMPOSITING_MODE=1
    export WEBKIT_DISABLE_DMABUF_RENDERER=1
    export LIBGL_ALWAYS_SOFTWARE=1
  '';

  extraInstallCommands = ''
    install -Dm444 "${appimageContents}/EVE Wrench.desktop" $out/share/applications/eve-wrench.desktop
    cp -r ${appimageContents}/usr/share/icons $out/share/icons
  '';

  meta = with lib; {
    description = "Backup, restore, and sync settings across EVE Online accounts and characters";
    homepage = "https://github.com/eve-wrench/eve-wrench-app";
    license = licenses.mit;
    platforms = [ "x86_64-linux" ];
    mainProgram = "eve-wrench";
  };
}
