{ config, inputs, lib, ... }:
let cfg = config.rhx.hyprland.caelestia;
in {
  imports = [ inputs.caelestia-shell.homeManagerModules.default ];

  options.rhx.hyprland.caelestia = {
    isLaptop = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description =
        "Whether the device is a laptop or not. Controls stuff like battery, brigthness, etc being visible.";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.caelestia = {
      enable = true;

      settings = {
        general = {
          apps = { terminal = [ "ghostty --gtk-single-instance=true" ]; };
        };
        status = { showBattery = cfg.isLaptop; };
        paths = { sessionGif = "undefined"; };
        services = {
          useFahrenheit = true;
          weatherLocation = "44.747998,-93.133574";
        };
      };

      cli = { enable = true; };
    };
  };
}
