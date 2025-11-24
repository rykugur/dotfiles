{ config, inputs, lib, username, ... }:
let cfg = config.rhx.mangowc;
in {
  imports = [ inputs.mangowc.nixosModules.mango ];

  options.rhx.niri = {
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

    rhx.caelestia.enable = (isBarEnabled "calestia");
    rhx.dankMaterialShell.enable = (isBarEnabled "dankMaterialShell");
    rhx.noctalia.enable = (isBarEnabled "noctalia");

    home-manager.users.${username}.imports = [ ./home.nix ];
  };
}
