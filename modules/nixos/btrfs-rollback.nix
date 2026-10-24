# Pre-mount Btrfs root rollback for impermanence: an initrd oneshot deletes
# the `root` subvolume and replaces it with a fresh snapshot of `root-blank`
# before `sysroot.mount`, so every boot starts from a clean root. Matches
# upstream nix-community/impermanence's own README Btrfs example. Fails
# closed: the script asserts `root-blank` exists before deleting anything.
# Host-specific persistence (`environment.persistence."/persist"`) is not
# part of this module — pair it with `inputs.impermanence.nixosModules.impermanence`
# and each host's own persist list.
{ ... }:
{
  flake.modules.nixos.btrfs-rollback =
    { config, pkgs, utils, ... }:
    let
      rootDevice = config.fileSystems."/".device;
      diskUnit = "${utils.escapeSystemdPath rootDevice}.device";
    in
    {
      boot.initrd.systemd = {
        enable = true;
        storePaths = [ pkgs.btrfs-progs ];
        services.rollback-root = {
          unitConfig.DefaultDependencies = false;
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
          };
          requiredBy = [ "sysroot.mount" ];
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
    };
}
