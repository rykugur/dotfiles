# Pinned to the testnet release channel because Eve Frontier's chain runs the
# testnet protocol version (per docs.evefrontier.com — `suiup install sui@testnet`).
# Do not switch to mainnet without confirming Eve Frontier's current protocol.
{
  stdenv,
  lib,
  fetchurl,
  autoPatchelfHook,
  openssl,
  version,
}:
let
  sources = {
    "x86_64-linux" = {
      url = "https://github.com/MystenLabs/sui/releases/download/testnet-v${version}/sui-testnet-v${version}-ubuntu-x86_64.tgz";
      sha256 = "sha256-l9bjpr6N4kwWKxjEgmBstjqnvJbAbrQ3iIw1sS/07lM=";
    };
    "aarch64-darwin" = {
      url = "https://github.com/MystenLabs/sui/releases/download/testnet-v${version}/sui-testnet-v${version}-macos-arm64.tgz";
      sha256 = "sha256-B94sfuUM75+nLGAfgR53tLpuRoJgoe76a5Upi7TtKao=";
    };
  };
  source =
    sources.${stdenv.hostPlatform.system}
      or (throw "sui: unsupported platform ${stdenv.hostPlatform.system}");
in
stdenv.mkDerivation {
  pname = "sui";
  inherit version;

  src = fetchurl source;

  sourceRoot = ".";

  nativeBuildInputs = lib.optionals stdenv.isLinux [ autoPatchelfHook ];
  buildInputs = lib.optionals stdenv.isLinux [ stdenv.cc.cc.lib ] ++ [ openssl ];

  installPhase = ''
    runHook preInstall
    install -Dm755 sui $out/bin/sui
    install -Dm755 move-analyzer $out/bin/move-analyzer
    runHook postInstall
  '';

  meta = {
    description = "Sui blockchain CLI and move-analyzer LSP (prebuilt from MystenLabs releases)";
    homepage = "https://github.com/MystenLabs/sui";
    platforms = [
      "x86_64-linux"
      "aarch64-darwin"
    ];
  };
}
