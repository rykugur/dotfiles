{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.ryk.virtualization.winboat;
in
{
  options.ryk.virtualization.winboat.enable =
    lib.mkEnableOption "Enable winboat (virtualization) module";

  config = lib.mkIf cfg.enable {
    ryk.virtualization.docker.enable = true;

    environment.systemPackages = [
      pkgs.winboat
      pkgs.freerdp
    ];
  };
}
