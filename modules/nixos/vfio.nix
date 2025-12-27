{ config, lib, pkgs, username, ... }:
let
  cfg = config.ryk.vfio;
  vfioIds = cfg.vfioIds;
  vfioIdsFmt = with builtins;
    if (length vfioIds > 0) then concatStringsSep "," vfioIds else "";
in {
  options.ryk.vfio = {
    enable = lib.mkEnableOption "Enable vfio nixOS module";
    vfioIds = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "A list of vfio device ids to pass through.";
    };
  };

  config = lib.mkIf cfg.enable {
    boot = {
      kernelParams = [ "amd_iommu=on" ];
      kernelModules =
        [ "kvm-amd" "vfio" "vfio_iommu_type1" "vfio_pci" "vfio_virqfd" ];
      extraModprobeConfig = "options vfio-pci ids=${vfioIdsFmt}";
    };

    hardware.graphics.enable = true;

    systemd.tmpfiles.rules =
      [ "f /dev/shm/looking-glass 0660 ${username} qemu-libvirtd -" ];

    environment.systemPackages = with pkgs; [ looking-glass-client OVMF ];

    programs.virt-manager.enable = true;

    virtualisation = {
      spiceUSBRedirection.enable = true;

      libvirtd = {
        enable = true;
        onBoot = "ignore";
        onShutdown = "shutdown";

        qemuOvmf = true;
        qemuRunAsRoot = true;

        qemu = {
          package = pkgs.qemu_kvm;
          # ovmf = enabled;
          verbatimConfig = ''
            namespaces = []
            user = "${username}"
          '';
        };
      };
    };

    users.users.${username}.extraGroups = [ "qemu-libvirtd" "libvirtd" "disk" ];
  };
}

# useful links
#
# https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF#Setting_up_IOMMU
#
# https://old.reddit.com/r/VFIO/comments/p4kmxr/tips_for_single_gpu_passthrough_on_nixos/
# -> https://pastebin.com/q3RQZYUS
#
# https://github.com/joeknock90/Single-GPU-Passthrough
#
#
