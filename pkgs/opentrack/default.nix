{ stdenv, fetchFromGitHub, fetchurl, makeDesktopItem, pkgs, }:
let
  # for neural-net face tracking
  onnxRuntime = fetchFromGitHub {
    owner = "microsoft";
    repo = "onnxruntime";
    rev = "v1.20.1";
    sha256 = "sha256-lOCXMEqpZtInE2aH6SKFoNSzzma0/cxgCXWvc2prloo=";
  };
  sdkSteamVr = fetchFromGitHub {
    owner = "ValveSoftware";
    repo = "openvr";
    rev = "v2.5.1";
    sha256 = "sha256-bIKjZ7DvJVmDK386WgXaAFQrS0E1TNEUMhfQp7FNnvk=";
  };
in stdenv.mkDerivation rec {
  name = "opentrack";
  # version = "2024.1.1";
  version = "2023.3.0";

  src = fetchFromGitHub {
    owner = "opentrack";
    repo = "opentrack";
    rev = "opentrack-${version}";
    sha256 = "sha256-C0jLS55DcLJh/e5yM8kLG7fhhKvBNllv5HkfCWRIfc4=";
  };

  nativeBuildInputs = with pkgs; [ cmake pkg-config ninja copyDesktopItems ];
  buildInputs = with pkgs;
    [ opencv4 procps eigen xorg.libXdmcp libevdev wineWowPackages.waylandFull ]
    ++ (with pkgs.libsForQt5.qt5; [ qtbase qttools wrapQtAppsHook ]);

  env.NIX_CFLAGS_COMPILE = "-Wall -Wextra -Wpedantic -ffast-math -O3";
  dontWrapQtApps = true;

  cmakeFlags = [
    "-DSDK_WINE=ON -DSDK_VALVE_STEAMVR=${sdkSteamVr} -DONNXRuntime_DIR=${onnxRuntime}"
  ];

  postInstall = ''
    wrapQtApp $out/bin/opentrack
  '';

  desktopItems = [
    (makeDesktopItem rec {
      name = "opentrack";
      exec = "opentrack";
      icon = fetchurl {
        url =
          "https://github.com/opentrack/opentrack/raw/opentrack-${version}/gui/images/opentrack.png";
        sha256 = "0d114zk78f7nnrk89mz4gqn7yk3k71riikdn29w6sx99h57f6kgn";
      };
      desktopName = name;
      genericName = "Head tracking software";
      categories = [ "Utility" ];
    })
  ];
}
