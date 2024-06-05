{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.libvirtd;
in {
  options = {
    services.libvirtd.enable = lib.mkEnableOption "enable libvirtd virtualization.";
  };

  config = lib.mkIf cfg.enable {
    virtualisation.libvirtd.enable = true;
    programs.virt-manager.enable = true;

    environment.systemPackages = with pkgs; [
      OVMF
    ];
  };
}
