{ config, lib, pkgs, ... }:
let cfg = config.rhx.head-tracking;
in {
  options.rhx.head-tracking = {
    enable = lib.mkEnableOption "Enable head-tracking home-manager module.";
    aitrack.enable = lib.mkEnableOption "Enable aitrack";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.opentrack ];
    # ++ (if cfg.aitrack.enable then [ pkgs.aitrack ] else [ ]);
  };
}
