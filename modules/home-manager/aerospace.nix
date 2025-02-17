{ config, inputs, lib, pkgs, hostname, ... }:
let cfg = config.rhx.aerospace;
in {
  options.rhx.aerospace = {
    enable = lib.mkEnableOption "Enable aerospace home-manager module.";
  };

  config = lib.mkIf cfg.enable { programs.aerospace = { enable = true; }; };
}
