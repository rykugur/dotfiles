{ lib
, stdenv
, fetchurl
  # , fetchFromGitHub
}:
{
  madnoodle-micro-pad = stdenv.mkDerivation rec {
    name = "madNoodleMicroPad";
    version = "1.0";

    src = fetchurl {
      url = "https://github.com/The-Mad-Noodle/Mad-Noodle-Via-Support/releases/download/v.1.0/noodlepad_micro.json";
      sha256 = "sha256-F6AxJcqBnNnIr18WvPEQ5O1RUQelUHPbCiXUq1jhRLM=";
    };

    preferLocalBuild = true;
    buildCommand = ''
      mkdir -p $out
      cp $src $out
    '';
  };
}
