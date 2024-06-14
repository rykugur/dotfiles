{ lib, stdenv, fetchFromGitHub, cmake, pkg-config, glib, check, }:
stdenv.mkDerivation rec {
  name = "n0la_rcon";
  version = "0.6";

  src = fetchFromGitHub {
    owner = "n0la";
    repo = "rcon";
    rev = version;
    sha256 = "sha256-bHm6JeWmpg42VZQXikHl+BMx9zimRLBQWemTqOxyLhw=";
  };

  buildInputs = [ cmake pkg-config glib check ];
}
