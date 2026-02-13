{ config, lib, ... }:
let cfg = config.ryk.btrfs;
in {
  options.ryk.btrfs.enable = lib.mkEnableOption "Enable btrfs nixOS module";

  config = lib.mkIf cfg.enable {
    services = {
      fstrim = {
        enable = true;
        interval = "weekly";
      };

      btrfs.autoScrub = {
        enable = true;
        interval = "monthly";
        fileSystems = [ "/" ];
      };
    };
  };
}
