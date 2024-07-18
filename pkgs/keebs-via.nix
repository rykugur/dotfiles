{ lib, stdenv, fetchurl, }:
let version = "2.0";
in {
  madnoodle-micro-pad = stdenv.mkDerivation {
    name = "madNoodleMicroPad";
    inherit version;

    src = fetchurl {
      url =
        "https://github.com/The-Mad-Noodle/Mad-Noodle-Via-Support/releases/download/v.${version}/noodlepad_micro.json";
      sha256 = "sha256-F6AxJcqBnNnIr18WvPEQ5O1RUQelUHPbCiXUq1jhRLM=";
    };

    preferLocalBuild = true;
    buildCommand = ''
      mkdir -p $out
      cp $src $out
    '';
  };

  madnoodle-udon13-v2 = stdenv.mkDerivation {
    name = "madNoodleUdon13v2";
    inherit version;

    src = fetchurl {
      url =
        "https://github.com/The-Mad-Noodle/Mad-Noodle-Via-Support/releases/download/v${version}/udon13v2.json";
      sha256 = "sha256-YS+QToYqFOQGUwn7Im/hSa+woNb0EHgvgavdEDpnDRU=";
    };

    preferLocalBuild = true;
    buildCommand = ''
      mkdir -p $out
      cp $src $out
    '';
  };
}
