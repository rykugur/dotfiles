{ config, inputs, lib, ... }:
let cfg = config.rhx.hyprland.caelestia;
in {
  imports = [ inputs.caelestia-shell.homeManagerModules.default ];
  config = lib.mkIf cfg.enable {
    programs.caelestia = {
      enable = true;

      settings = {
        services = {
          useFahrenheit = true;
          weatherLocation = "44.747998,-93.133574";
        };
      };
      # extraConfig = {};
      cli = {
        enable = true;

        # settings = {};
        # extraConfig = {};
      };
    };
  };
}
