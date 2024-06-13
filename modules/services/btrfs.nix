{
  config,
  lib,
  ...
}: let
  cfg = config.services.btrfs;
in {
  options = {
    services.btrfs.enable = lib.mkEnableOption "Enable BTRFS";
  };

  config = lib.mkIf cfg.enable {
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
  };
}
