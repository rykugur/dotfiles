{
  lib,
  rustPlatform,
  fetchFromGitHub,
  pkg-config,
  libusb1,
}:
rustPlatform.buildRustPackage {
  pname = "xr-to-opentrack";
  # No upstream tags; commit pinned to last meaningful change.
  version = "unstable-2025-02-27";

  src = fetchFromGitHub {
    owner = "hodasemi";
    repo = "xr_to_opentrack_rs";
    rev = "ef97b84cc1d39949c5a5d43f790cb1a3ab0314c4";
    hash = "sha256-TXMUJeupqnUNQNYWeN9qXm0HFVo7PtjRXj040ITeKqM=";
  };

  # Upstream ships no Cargo.lock; vendored alongside this file.
  cargoLock.lockFile = ./xr-to-opentrack.Cargo.lock;

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ libusb1 ];

  # build.rs links the vendored static SDK at viture_one_linux_sdk_1.0.7/libs/
  # (libviture_one_sdk_static.a — proprietary VITURE blob baked into the binary).

  meta = {
    description = "Bridge VITURE One XR glasses IMU to OpenTrack via UDP";
    homepage = "https://github.com/hodasemi/xr_to_opentrack_rs";
    license = lib.licenses.unfree;
    platforms = [ "x86_64-linux" ];
    mainProgram = "xr_to_opentrack_rs";
  };
}
