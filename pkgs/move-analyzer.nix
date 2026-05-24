{
  rustPlatform,
  fetchFromGitHub,
  version,
}:
let
  src = fetchFromGitHub {
    owner = "MystenLabs";
    repo = "sui";
    rev = "testnet-v${version}";
    sha256 = "sha256-4bmuy4fWUqJoBV/Xy1EcPIIcKOonT6jx8r4bVRUnsjg=";
  };
in
rustPlatform.buildRustPackage {
  pname = "move-analyzer";
  inherit version src;

  cargoLock = {
    lockFile = "${src}/Cargo.lock";
    outputHashes = {
      "alloy-multiprovider-strategy-0.1.0" = "sha256-a+Ilc9cy8S1/hR/0ymM+7wKvRVXp4LTN/s9FUL8EwU8=";
      "anemo-0.0.0" = "sha256-50SQm1lGqaKznOgR/zxOwiYIzX1okVB2HCjOdrnFR10=";
      "async-graphql-7.0.1" = "sha256-p2mcRE5PlwnF6w1eZtMT+CtTb7CoAyqJJ/Nmcur+Wjs=";
      "async-task-4.3.0" = "sha256-zMTWeeW6yXikZlF94w9I93O3oyZYHGQDwyNTyHUqH8g=";
      "datatest-stable-0.1.3" = "sha256-VAdrD5qh6OfabMUlmiBNsVrUDAecwRmnElmkYzba+H0=";
      "fastcrypto-0.1.9" = "sha256-1/WgbAUosm4udvro7eJDqhieQLd20QpOTnsvQtS62Fs=";
      "json_to_table-0.6.0" = "sha256-UKMTa/9WZgM58ChkvQWs1iKWTs8qk71gG+Q/U/4D4x4=";
      "minibytes-0.1.0" = "sha256-oI7KI+VLsWm/UCjbSkMEwJjTrR+il83HyGw+OHpm7Yk=";
      "msim-0.1.0" = "sha256-FqjDJayizfAH8yyxX95eul5Wp8XgUghAnLhBKjx6haE=";
      "nexlint-0.1.0" = "sha256-L9vf+djTKmcz32IhJoBqAghQ8mS3sc9I2C3BBDdUxkQ=";
      "real_tokio-1.52.1" = "sha256-r0eaNw8Jc3QtomC2X0dg97M6uLo52gi9lLc2fMe7JjE=";
      "sui-crypto-0.3.0" = "sha256-lejrD7c7JAkU4lqStrlt3l5x8KsZsLhWYY07VsiWnjs=";
      "tonic-0.14.5" = "sha256-hWJF3JA/YWIbWbASwm3qEKNdrTAdVcOtBYI8QyzsOMg=";
    };
  };

  buildAndTestSubdir = "external-crates/move/crates/move-analyzer";

  doCheck = false;

  meta = {
    description = "Move language server (from MystenLabs/sui)";
    homepage = "https://github.com/MystenLabs/sui";
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
  };
}
