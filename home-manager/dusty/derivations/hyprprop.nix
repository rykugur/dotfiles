{ lib
, stdenv
, fetchFromGitHub
}:

stdenv.mkDerivation {
  name = "hyprprop";

  src = fetchFromGitHub {
    owner = "vilari-mickopf";
    repo = "hyprprop";
    rev = "77e154aaaaee911f66187689d878a41f97fabc51";
    sha256 = "sha256-5CijOK0gW8w9MY0xmLj5tZ7c/3UfrshXAABv8Ui0Hds=";
  };

  buildPhase = ''
    PREFIX=./build make
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    cp ./build/bin/hyprprop $out/bin

    runHook postInstall
  '';
}
