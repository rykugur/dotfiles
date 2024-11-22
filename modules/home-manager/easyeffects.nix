{ config, lib, pkgs, ... }:
let cfg = config.rhx.easyeffects;
in {
  options.rhx.easyeffects = {
    enable = lib.mkEnableOption "Enable easyeffects home-manager module.";
  };

  config = lib.mkIf cfg.enable {
    services.easyeffects = {
      enable = true;
      package = pkgs.easyeffects;
    };

    home.file = {
      ".config/easyeffects/input/input.json".source =
        ../../configs/easyeffects/input/improved-microphone-male-voices.json;
      ".config/easyeffects/output/output.json".source =
        ../../configs/easyeffects/output/heavy-bass.json;
    };
  };
}
