{
  lib,
  appimageTools,
  fetchurl,
}:

let
  version = "02.08.02.60";
  pname = "bambu-studio";

  src = fetchurl {
    url = "https://github.com/bambulab/BambuStudio/releases/download/v${version}/BambuStudio_ubuntu24.04-v${version}-20260814171356.AppImage";
    sha256 = "sha256-t40lJ6IO6fvPcO6CE4w7PKcHqpxmJYgWKdspYnJSrMM=";
  };

  appimageContents = appimageTools.extract { inherit pname version src; };
in
appimageTools.wrapType2 {
  inherit pname version src;

  extraPkgs = pkgs: [
    pkgs.fontconfig
    pkgs.libGL
    pkgs.gtk3
    pkgs.glib
    pkgs.libx11
    pkgs.gst_all_1.gstreamer
    pkgs.gst_all_1.gst-plugins-base
    pkgs.gst_all_1.gst-plugins-good
    pkgs.gst_all_1.gst-plugins-bad
    pkgs.webkitgtk_4_1
    pkgs.dbus
    pkgs.wayland
  ];

  extraInstallCommands = ''
    install -Dm444 "${appimageContents}/BambuStudio.desktop" $out/share/applications/bambu-studio.desktop
    install -Dm444 "${appimageContents}/BambuStudio.png" $out/share/icons/hicolor/256x256/apps/bambu-studio.png
    substituteInPlace $out/share/applications/bambu-studio.desktop \
      --replace-fail 'Exec=AppRun %U' 'Exec=bambu-studio %U' \
      --replace-fail 'Icon=BambuStudio' 'Icon=bambu-studio'
  '';

  meta = with lib; {
    description = "A cutting-edge, feature-rich slicing software for Bambu Lab 3D printers";
    homepage = "https://bambulab.com/en/download/studio";
    license = licenses.unfree;
    platforms = [ "x86_64-linux" ];
    mainProgram = "bambu-studio";
  };
}
