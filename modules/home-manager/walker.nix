{ config, lib, ... }:
let cfg = config.ryk.walker;
in {
  options.ryk.walker = {
    enable = lib.mkEnableOption "Enable walker home-manager module.";
  };

  config = lib.mkIf cfg.enable { services.walker = { enable = true; }; };
}
