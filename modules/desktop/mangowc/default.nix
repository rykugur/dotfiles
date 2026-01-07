{ config, inputs, lib, username, ... }:
let cfg = config.ryk.mangowc;
in {
  imports = [ inputs.mangowc.nixosModules.mango ];

  options.ryk.niri = {
    enable = lib.mkEnableOption "Enable mangowc window manager.";

    monitors = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "Monitors to define.";
    };
  };

  config = let isBarEnabled = bar: cfg.bar == bar;
  in lib.mkIf cfg.enable {
    programs.mango.enable = true;

    ryk.caelestia.enable = (isBarEnabled "calestia");
    ryk.dankMaterialShell.enable = (isBarEnabled "dankMaterialShell");
    ryk.noctalia.enable = (isBarEnabled "noctalia");

    home-manager.users.${username}.imports = [ ./home.nix ];
  };
}
