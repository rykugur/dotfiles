{ config, lib, pkgs, username, ... }:
let cfg = config.modules.programs.virtman;
in {
  options.modules.programs.virtman.enable =
    lib.mkEnableOption "Enable Virt-manager";

  config = lib.mkIf cfg.enable {

    environment.systemPackages = with pkgs; [ virtiofsd ];

    virtualisation.libvirtd = {
      enable = true;
      qemu = {
        package = pkgs.qemu_kvm;
        runAsRoot = true;
        swtpm.enable = true;
        ovmf = {
          enable = true;
          packages = [
            (pkgs.OVMF.override {
              secureBoot = true;
              tpmSupport = true;
            }).fd
          ];
        };
      };
    };
    programs.virt-manager.enable = true;

    users.users.${username}.extraGroups = [ "libvirtd" ];
  };
}
