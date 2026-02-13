{ config, lib, ... }:
let cfg = config.ryk.flameshot;
in {
  options.ryk.flameshot = {
    enable = lib.mkEnableOption "Enable flameshot home-manager module.";
  };

  config = lib.mkIf cfg.enable { services.flameshot.enable = true; };
}
