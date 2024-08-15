{ config, lib, ... }:
let cfg = config.modules.programs.virtman;
in {
  options.modules.programs.virtman.enable =
    lib.mkEnableOption "Enable Virt-manager";

  config = lib.mkIf cfg.enable {
    virtualisation.libvirtd.enable = true;
    programs.virt-manager.enable = true;
  };
}
