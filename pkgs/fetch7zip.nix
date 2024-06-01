{
  fetchurl,
  pkgs,
  stdenv,
  ...
}: {
  url,
  sha256,
}:
stdenv.mkDerivation
{
  name = "fetch7zip";
  src = fetchurl {inherit url sha256;};

  nativeBuildInputs = [pkgs.p7zip];

  phases = ["installPhase"];

  installPhase = ''
    mkdir -p $out
    cd $out
    7za x $src -o$out
  '';
}
