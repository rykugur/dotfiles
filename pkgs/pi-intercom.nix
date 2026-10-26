{
  lib,
  stdenvNoCC,
  fetchurl,
}:

stdenvNoCC.mkDerivation {
  pname = "pi-intercom";
  version = "0.18.1";

  src = fetchurl {
    url = "https://registry.npmjs.org/pi-intercom/-/pi-intercom-0.18.1.tgz";
    hash = "sha256-FmOlMOtIKyPaZtkOJwvTJrvlaKnHw9PMdXW8f0U1p+0=";
  };

  dontUnpack = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p "$out"
    tar -xzf "$src" --strip-components=1 -C "$out"
    runHook postInstall
  '';

  meta = {
    description = "Pi-compatible inter-session communication extension";
    homepage = "https://github.com/nicobailon/pi-intercom";
    license = lib.licenses.mit;
    platforms = lib.platforms.unix;
  };
}
