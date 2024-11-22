{ config, lib, username, pkgs, ... }:
let cfg = config.rhx.virtman;
in {
  options.rhx.virtman.enable = lib.mkEnableOption "Enable virtman nixOS module";

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
