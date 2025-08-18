{ config, lib, ... }:
let cfg = config.rhx.walker;
in {
  options.rhx.walker = {
    enable = lib.mkEnableOption "Enable walker home-manager module.";
  };

  config = lib.mkIf cfg.enable { services.walker = { enable = true; }; };
}
