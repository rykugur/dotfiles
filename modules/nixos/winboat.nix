{ config, lib, pkgs, ... }:
let cfg = config.rhx.winboat;
in {
  options.rhx.winboat.enable = lib.mkEnableOption "Enable winboat nixOS module";

  config = lib.mkIf cfg.enable {
    rhx.docker.enable = true;

    environment.systemPackages = [ pkgs.winboat pkgs.freerdp ];
  };
}
