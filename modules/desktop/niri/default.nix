{ config, inputs, lib, username, ... }:
let
  cfg = config.ryk.niri;
  shared = import ../shared.nix;
  barNames = shared.bars;
in {
  imports = [ inputs.niri.nixosModules.niri ];

  options.ryk.niri = {
    enable = lib.mkEnableOption "Enable niri window manager.";

    monitors = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "Monitors to define.";
    };

    touch = lib.mkOption {
      type = lib.types.nullOr (lib.types.submodule {
        options = {
          input = lib.mkOption {
            type = lib.types.nullOr (lib.types.str);
            default = null;
            description =
              ''Name of the touch input monitor. Example: "HDMI-A-1."'';
          };

          rotation = lib.mkOption {
            type = lib.types.nullOr (lib.types.enum [ "0" "90" "180" "270" ]);
            default = null;
            description =
              "Touch rotation direction; generates libinput calibration-matrix accordingly.";
            example = "90";
          };
        };
      });
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
      default = [ 0.33 0.66 1.0 ];
    };
  };

  config = let isBarEnabled = bar: cfg.bar == bar;
  in lib.mkIf cfg.enable {
    programs.niri.enable = true;

    # ryk.caelestia.enable = (isBarEnabled "caelestia");
    ryk.dankMaterialShell.enable = (isBarEnabled "dankMaterialShell");
    ryk.noctalia.enable = (isBarEnabled "noctalia");

    home-manager.users.${username}.imports = [ ./home.nix ];
  };
}
