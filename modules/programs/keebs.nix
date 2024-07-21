# mechanical keyboards
{ config, lib, pkgs, username, ... }:
let
  cfg = config.modules.programs.keebs;
  madnoodle-micro-pad = pkgs.fetchurl {
    url =
      "https://github.com/The-Mad-Noodle/Mad-Noodle-Via-Support/releases/download/v.2.0/noodlepad_micro.json";
    sha256 = "sha256-F6AxJcqBnNnIr18WvPEQ5O1RUQelUHPbCiXUq1jhRLM=";
  };
  madnoodle-udon13-v2 = pkgs.fetchurl {
    url =
      "https://github.com/The-Mad-Noodle/Mad-Noodle-Via-Support/releases/download/v2.0/udon13v2.json";
    sha256 = "sha256-YS+QToYqFOQGUwn7Im/hSa+woNb0EHgvgavdEDpnDRU=";
  };
in {
  options.modules.programs.keebs.enable =
    lib.mkEnableOption "Enable keebs (mechanical keyboards) module.";

  config = lib.mkIf cfg.enable {
    hardware.keyboard.qmk.enable = true;

    environment.systemPackages = [ pkgs.via pkgs.vial ];

    services.udev.packages = [ pkgs.via pkgs.vial ];

    home-manager.users.${username} = {
      home = {
        packages = [ pkgs.qmk ];

        file = {
          ".via-config-files/noodlepad-micro.json" = {
            source = "${madnoodle-micro-pad}";
          };
          ".via-config-files/noodlepad-udon13-v2.json" = {
            source = "${madnoodle-udon13-v2}";
          };
          ".via-config-files/doio-kb16-01.json" = {
            source = ../../configs/misc/kb16-01.json;
          };
        };
      };
    };
  };
}
