{ config, lib, ... }:
let cfg = config.rhx.obs;
in {
  options.rhx.obs = {
    enable = lib.mkEnableOption "Enable obs home-manager module.";
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
