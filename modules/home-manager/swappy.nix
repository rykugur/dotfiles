{ config, lib, ... }:
let cfg = config.rhx.swappy;
in {
  options.rhx.swappy = {
    enable = lib.mkEnableOption "Enable swappy home-manager module.";
  };

  config = lib.mkIf cfg.enable {
    home.file = {
      ".config/swappy" = {
        source = ../../configs/swappy;
        recursive = true;
      };
    };
  };
}
