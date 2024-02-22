{ lib
, stdenv
, fetchFromGitHub
, cmake
, makeWrapper
, ninja
, pkg-config
, curl
, SDL2
, lz4
, p7zip
, gnome
}:
stdenv.mkDerivation rec {
  name = "lampray";

  src = fetchFromGitHub {
    owner = "CHollingworth";
    repo = "Lampray";
    rev = "4673fef332976b991368aaeb62b968f531ab71ad";
    sha256 = "sha256-yZiH3YCO1HlBpQhaVehTZF8UHwZ8zbqAqcX2aRijH20=";
  };

  nativeBuildInputs = [
    cmake
    makeWrapper
    ninja
    pkg-config
  ];

  buildInputs = [
    curl
    SDL2
    lz4
    p7zip
    gnome.zenity
  ];

  prePatch = ''
    sed -i 's|const lampString baseDataPath = "Lamp_Data/";|const lampString baseDataPath = ((std::string)std::getenv("HOME")) + "/.lamp/";|g' Lampray/Control/lampConfig.h
  '';

  preBuild = ''
    grep baseDataPath /build/source/Lampray/Control/lampConfig.h
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    cp ./Lampray $out/bin/Lampray

    makeWrapper $out/bin/Lampray $out/bin/lampray_wrapper \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [ lz4 ]}

    runHook postInstall
  '';
}
