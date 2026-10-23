{
  # Single 238G NVMe (the box shipped with a Windows layout; this wipes it).
  # Same btrfs shape as nale, plus a dedicated subvolume for Incus so guest
  # volumes are separable from the host's own state and can be snapshotted or
  # sent without dragging /nix along. `/persist` exists from day one so
  # impermanence can be switched on later without repartitioning.
  disko.devices.disk.main = {
    type = "disk";
    device = "/dev/nvme0n1";
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          size = "512M";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = [ "umask=0077" ];
          };
        };
        root = {
          size = "100%";
          content = {
            type = "btrfs";
            extraArgs = [ "-f" ];
            subvolumes = {
              "/root" = {
                mountpoint = "/";
                mountOptions = [
                  "compress=zstd"
                  "noatime"
                ];
              };
              "/nix" = {
                mountpoint = "/nix";
                mountOptions = [
                  "compress=zstd"
                  "noatime"
                ];
              };
              "/persist" = {
                mountpoint = "/persist";
                mountOptions = [
                  "compress=zstd"
                  "noatime"
                ];
              };
              "/home" = {
                mountpoint = "/home";
                mountOptions = [ "compress=zstd" ];
              };
              # Incus creates its storage pool as child subvolumes of this one.
              "/incus" = {
                mountpoint = "/var/lib/incus";
                mountOptions = [ "noatime" ];
              };
            };
          };
        };
      };
    };
  };

  fileSystems."/persist".neededForBoot = true;
}
