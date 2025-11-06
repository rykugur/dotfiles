{ config, inputs, lib, username, ... }:
let cfg = config.rhx.niri;
in {
  imports = [ inputs.niri.nixosModules.niri ];

  options.rhx.niri = {
    enable = lib.mkEnableOption "Enable niri nixOS module";

    monitors = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "Monitors to define.";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.niri.enable = true;

    home-manager.users.${username}.imports = [ ./home.nix ];
  };
}
