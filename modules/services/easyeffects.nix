{ config, lib, pkgs, username, ... }:
let cfg = config.services.easyeffectsz;
in {
  options.services.easyeffectsz.enable =
    lib.mkEnableOption "Enable easyeffects";

  config = lib.mkIf cfg.enable {
    programs.dconf.enable = true;

    home-manager.users.${username} = {
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
  };
}
