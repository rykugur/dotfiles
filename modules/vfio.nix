{ ... }:
{
  flake.nixosModules.vfio =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.ryk.vfio;
      metaCfg = config.meta.ryk;

      vfioIds = cfg.vfioIds;
      vfioIdsFmt = with builtins; if (length vfioIds > 0) then concatStringsSep "," vfioIds else "";
    in
    {
      options.ryk.vfio = {
        enable = lib.mkEnableOption "Enable vfio nixOS module";
        vfioIds = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "A list of vfio device ids to pass through.";
        };
      };

      boot = {
        kernelParams = [ "amd_iommu=on" ];
        kernelModules = [
          "kvm-amd"
          "vfio"
          "vfio_iommu_type1"
          "vfio_pci"
          "vfio_virqfd"
        ];
        extraModprobeConfig = "options vfio-pci ids=${vfioIdsFmt}";
      };

      hardware.graphics.enable = true;

      systemd.tmpfiles.rules = [ "f /dev/shm/looking-glass 0660 ${metaCfg.username} qemu-libvirtd -" ];

      environment.systemPackages = with pkgs; [
        looking-glass-client
        OVMF
      ];

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
              user = "${metaCfg.username}"
            '';
          };
        };
      };

      users.users.${metaCfg.username}.extraGroups = [
        "qemu-libvirtd"
        "libvirtd"
        "disk"
      ];
    };
}
