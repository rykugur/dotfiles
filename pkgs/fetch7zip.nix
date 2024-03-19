{ fetchurl, pkgs, src, stdenv, ... }: stdenv.mkDerivation
{
  name = "fetch7zip";
  inherit src;

  nativeBuildInputs = [ pkgs.p7zip ];

  phases = [ "installPhase" ];

  installPhase = ''
    mkdir -p $out
    cd $out
    7za x $src
  '';
}
