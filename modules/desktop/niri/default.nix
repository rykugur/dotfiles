{ config, inputs, lib, username, ... }:
let
  cfg = config.rhx.niri;
  barNames = (import ../shared.nix).bars;
in {
  imports = [ inputs.niri.nixosModules.niri ];

  options.rhx.niri = {
    enable = lib.mkEnableOption "Enable niri window manager.";

    monitors = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "Monitors to define.";
    };

    bar = lib.mkOption {
      type = lib.types.enum barNames;
      default = "none";
    };

    screenshotBackend = lib.mkOption {
      type = lib.types.enum [ "swappy" "satty" "none" ];
      default = "none";
    };
  };

  config = let isBarEnabled = bar: cfg.bar == bar;
  in lib.mkIf cfg.enable {
    programs.niri.enable = true;

    # rhx.caelestia.enable = (isBarEnabled "caelestia");
    rhx.dankMaterialShell.enable = (isBarEnabled "dankMaterialShell");
    rhx.noctalia.enable = (isBarEnabled "noctalia");

    home-manager.users.${username}.imports = [ ./home.nix ];
  };
}
