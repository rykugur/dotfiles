{
  config,
  lib,
  pkgs,
  username,
  ...
}: let
  cfg = config.services.easyeffectsz;
in {
  options.services.easyeffectsz.enable = lib.mkEnableOption "Enable easyeffects";

  config = lib.mkIf cfg.enable {
    programs.dconf.enable = true;

    home-manager.users.${username} = {
      services.easyeffects = {
        enable = true;
        package = pkgs.easyeffects;
      };

      systemd.user.services.easyeffects = {
        Unit = {
          Description = "easyeffects daemon";
          PartOf = "graphical-session.target";
          After = "graphical-session.target";
        };
        Service = {
          Environment = "easyeffects";
          ExecStart = "${pkgs.easyeffects}/bin/easyeffects --gapplication-service";
          Restart = "on-failure";
        };
        Install = {
          WantedBy = "graphical-session.target";
        };
      };

      home.file = {
        ".config/easyeffects/input/input.json".source = ../../configs/easyeffects/input/improved-microphone-male-voices.json;
        ".config/easyeffects/output/output.json".source = ../../configs/easyeffects/output/heavy-bass.json;
      };
    };
  };
}
