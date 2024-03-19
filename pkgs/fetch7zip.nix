{ fetchurl, pkgs, name, src, stdenv, ... }: stdenv.mkDerivation
{
  inherit name src;

  nativeBuildInputs = [ pkgs.p7zip ];

  phases = [ "installPhase" ];

  installPhase = ''
    mkdir -p $out
    cd $out
    7za x $src
  '';
}
