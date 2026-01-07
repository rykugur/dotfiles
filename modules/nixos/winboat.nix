{ config, lib, pkgs, ... }:
let cfg = config.ryk.winboat;
in {
  options.ryk.winboat.enable = lib.mkEnableOption "Enable winboat nixOS module";

  config = lib.mkIf cfg.enable {
    ryk.docker.enable = true;

    environment.systemPackages = [ pkgs.winboat pkgs.freerdp ];
  };
}
