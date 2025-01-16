{ config, lib, ... }:
let cfg = config.rhx.starcitizen;
in {
  options.rhx.starcitizen = {
    enable = lib.mkEnableOption "Enable starcitizen home-manager module.";
  };

  config = lib.mkIf cfg.enable {
    rhx = {
      head-tracking.enable = true;
      gameglass.enable = true;
    };
  };
}
