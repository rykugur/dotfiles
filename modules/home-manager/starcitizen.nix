{ config, lib, pkgs, ... }:
let cfg = config.rhx.starcitizen;
in {
  options.rhx.starcitizen = {
    enable = lib.mkEnableOption "Enable starcitizen home-manager module.";
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [ opentrack ];

    # disabling until I decide how to proceed
    # rhx = { gameglass.enable = true; };
  };
}
