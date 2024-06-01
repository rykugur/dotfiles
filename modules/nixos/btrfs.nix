{
  config,
  inputs,
  lib,
  ...
}: {
  services = {
    fstrim = {
      enable = true;
      interval = "weekly";
    };

    btrfs.autoScrub = {
      enable = true;
      interval = "monthly";
      fileSystems = ["/"];
    };
  };
}
