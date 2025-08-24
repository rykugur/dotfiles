{ config, inputs, lib, ... }:
let cfg = config.rhx.hyprland.quickshell;
in {
  imports = [ inputs.caelestia-shell.homeManagerModules.default ];

  config = lib.mkIf cfg.enable {
    programs.caelestia = {
      enable = true;

      # settings = {};
      # extraConfig = {};
      cli = {
        enable = true;

        # settings = {};
        # extraConfig = {};
      };
    };
  };
}
