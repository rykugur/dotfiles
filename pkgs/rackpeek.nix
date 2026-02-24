{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  icu,
  openssl,
  zlib,
}:
let
  version = "0.0.4";
  sources = {
    "x86_64-linux" = {
      url = "https://github.com/Timmoth/RackPeek/releases/download/RackPeek-${version}/rackpeek_0_0_4_linux-x64";
      hash = "sha256-X5cXu+A6UxKc34fl15uwnO6JRNI9oi5pK8Tt2ldYnj4=";
    };
    "aarch64-linux" = {
      url = "https://github.com/Timmoth/RackPeek/releases/download/RackPeek-${version}/rackpeek_0_0_4_linux-arm64";
      hash = "sha256-2qdAaY18223xWsg7PWjDE6swhWb+5WOJyNklOkBL4e0=";
    };
    "aarch64-darwin" = {
      url = "https://github.com/Timmoth/RackPeek/releases/download/RackPeek-${version}/rackpeek_0_0_4_osx-arm64";
      hash = "sha256-I/mEm5uNDRlnRgOrsGVeoSv9sHkO3GmnzOmN9uBqmzA=";
    };
    "x86_64-darwin" = {
      url = "https://github.com/Timmoth/RackPeek/releases/download/RackPeek-${version}/rackpeek_0_0_4_osx-x64";
      hash = "sha256-y+UHULD2RvlutYHFgUDGdtNeVJlpjZQYHMfr8+lqFkw=";
    };
  };
  src = fetchurl sources.${stdenv.hostPlatform.system};
in
stdenv.mkDerivation {
  pname = "rackpeek";
  inherit version src;

  dontUnpack = true;
  dontStrip = true;

  nativeBuildInputs = lib.optionals stdenv.hostPlatform.isLinux [ autoPatchelfHook ];

  buildInputs = lib.optionals stdenv.hostPlatform.isLinux [
    stdenv.cc.cc.lib
    icu
    openssl
    zlib
  ];

  installPhase = ''
    install -Dm755 $src $out/bin/rpk
  '';

  meta = {
    homepage = "https://github.com/Timmoth/RackPeek";
    description = "A lightweight CLI tool for documenting and managing home lab infrastructure";
    license = lib.licenses.agpl3Only;
    platforms = builtins.attrNames sources;
    mainProgram = "rackpeek";
  };
}
