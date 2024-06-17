{ config, lib, pkgs, username, ... }:
let cfg = config.modules.programs.obs;
in {
  options.modules.programs.obs.enable = lib.mkEnableOption "Enable OBS.";
  config = lib.mkIf cfg.enable {
    home-manager.users.${username} = {
      programs.obs-studio = {
        enable = true;
        plugins = [ ];
        package = pkgs.obs-studio;
      };

      home.packages = [
        # pkgs.obs-studio
        pkgs.obs-cli
        pkgs.obs-studio-plugins.input-overlay
        pkgs.obs-studio-plugins.wlrobs
      ];
    };
  };
}
