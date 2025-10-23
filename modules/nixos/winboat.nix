{ config, inputs, lib, pkgs, ... }:
let cfg = config.rhx.winboat;
in {
  options.rhx.winboat.enable = lib.mkEnableOption "Enable winboat nixOS module";

  config = lib.mkIf cfg.enable {
    rhx.docker.enable = true;

    environment.systemPackages =
      [ inputs.winboat.packages.${pkgs.system}.winboat pkgs.freerdp ];
  };
}
