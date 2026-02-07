{ lib, ... }:
let
  shared = import ../_shared.nix;
  barNames = shared.bars;
in
{
  options.ryk.niri = {
    enable = lib.mkEnableOption "Enable niri; this only exists temporarily, since the niri HM module doesn't seem to provide an enable flag";

    monitors = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "Monitors to define.";
    };

    touch = lib.mkOption {
      type = lib.types.nullOr (
        lib.types.submodule {
          options = {
            input = lib.mkOption {
              type = lib.types.nullOr (lib.types.str);
              default = null;
              description = ''Name of the touch input monitor. Example: "HDMI-A-1."'';
            };

            rotation = lib.mkOption {
              type = lib.types.nullOr (
                lib.types.enum [
                  "0"
                  "90"
                  "180"
                  "270"
                ]
              );
              default = null;
              description = "Touch rotation direction; generates libinput calibration-matrix accordingly.";
              example = "90";
            };
          };
        }
      );
    };

    bar = lib.mkOption {
      type = lib.types.enum barNames;
      default = "none";
    };

    additionalRules = lib.mkOption {
      type = lib.types.nullOr (lib.types.listOf lib.types.attrs);
      default = null;
    };

    # TODO: use this in home.nix
    defaultColumnWidth = lib.mkOption {
      type = lib.types.float;
      default = 0.66;
    };

    # TODO: use this in home.nix
    proportions = lib.mkOption {
      type = lib.types.listOf lib.types.float;
      default = [
        0.33
        0.66
        1.0
      ];
    };
  };
}
