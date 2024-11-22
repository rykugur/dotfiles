{ config, lib, pkgs, ... }:
let cfg = config.rhx.obs;
in {
  options.rhx.obs = {
    enable = lib.mkEnableOption "Enable obs home-manager module.";
  };

  config = lib.mkIf cfg.enable {
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
}
