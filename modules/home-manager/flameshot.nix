{ config, lib, ... }:
let cfg = config.rhx.flameshot;
in {
  options.rhx.flameshot = {
    enable = lib.mkEnableOption "Enable flameshot home-manager module.";
  };

  config = lib.mkIf cfg.enable { services.flameshot.enable = true; };
}
