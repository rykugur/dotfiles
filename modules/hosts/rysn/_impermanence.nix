{ config, inputs, pkgs, utils, ... }:
let
  rootDevice = config.fileSystems."/".device;
  diskUnit = "${utils.escapeSystemdPath rootDevice}.device";
in
{
  imports = [ inputs.impermanence.nixosModules.impermanence ];

  boot.initrd.systemd = {
    enable = true;
    storePaths = [ pkgs.btrfs-progs ];
    services.rollback-root = {
      unitConfig.DefaultDependencies = false;
      serviceConfig.Type = "oneshot";
      wantedBy = [ "initrd.target" ];
      before = [ "sysroot.mount" ];
      requires = [ diskUnit ];
      after = [ diskUnit "local-fs-pre.target" ];
      script = ''
        mkdir -p /btrfs_tmp
        mount -o subvol=/ ${rootDevice} /btrfs_tmp
        trap 'umount /btrfs_tmp' EXIT
        # Fail closed: never boot a stale root if the template is missing.
        ${pkgs.btrfs-progs}/bin/btrfs subvolume show /btrfs_tmp/root-blank >/dev/null
        ${pkgs.btrfs-progs}/bin/btrfs subvolume delete --recursive /btrfs_tmp/root
        ${pkgs.btrfs-progs}/bin/btrfs subvolume snapshot /btrfs_tmp/root-blank /btrfs_tmp/root
      '';
    };
  };

  environment.persistence."/persist" = {
    hideMounts = true;
    directories = [
      "/etc/ssh"
      "/var/lib/nixos"
      "/var/log/journal"
    ];
    files = [ "/etc/machine-id" ];
  };
}
