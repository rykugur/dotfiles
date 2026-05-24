{
  stdenv,
  fetchurl,
  autoPatchelfHook,
  openssl,
  version,
}:
stdenv.mkDerivation {
  pname = "sui";
  inherit version;

  src = fetchurl {
    url = "https://github.com/MystenLabs/sui/releases/download/testnet-v${version}/sui-testnet-v${version}-ubuntu-x86_64.tgz";
    sha256 = "sha256-l9bjpr6N4kwWKxjEgmBstjqnvJbAbrQ3iIw1sS/07lM=";
  };

  sourceRoot = ".";

  nativeBuildInputs = [ autoPatchelfHook ];
  buildInputs = [
    stdenv.cc.cc.lib
    openssl
  ];

  installPhase = ''
    runHook preInstall
    install -Dm755 sui $out/bin/sui
    runHook postInstall
  '';

  meta = {
    description = "Sui blockchain CLI (prebuilt from MystenLabs releases)";
    homepage = "https://github.com/MystenLabs/sui";
    platforms = [ "x86_64-linux" ];
  };
}
