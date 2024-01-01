{ config, inputs, lib, ... }: {
  services = {
    trim = {
      enable = true;
      interval = "weekly";
    };

    btrfs.autoScrub = {
      enable = true;
      interval = "monthly";
      fileSystems = [ "/" ];
    };
  };
}
