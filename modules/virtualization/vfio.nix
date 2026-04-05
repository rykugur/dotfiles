{ ... }:
{
  flake.modules.nixos.vfio =
    { config, lib, username, pkgs, ... }:
    let
      cfg = config.ryk.vfio;
      vfioIds = cfg.ids;
      vfioIdsFmt = with builtins;
        if (length vfioIds > 0) then concatStringsSep "," vfioIds else "";
    in
    {
      options.ryk.vfio.ids = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "A list of vfio PCI device IDs to pass through.";
      };

      config = {
        boot = {
          kernelParams = [ "amd_iommu=on" ];
          kernelModules = [ "kvm-amd" "vfio" "vfio_iommu_type1" "vfio_pci" "vfio_virqfd" ];
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
              verbatimConfig = ''
                namespaces = []
                user = "${username}"
              '';
            };
          };
        };

        users.users.${username}.extraGroups = [ "qemu-libvirtd" "libvirtd" "disk" ];
      };
    };
}
