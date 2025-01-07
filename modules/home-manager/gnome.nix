{ config, lib, ... }:
let cfg = config.rhx.gnome;
in {
  options.rhx.gnome = {
    enable = lib.mkEnableOption "Enable gnome home-manager module.";
  };

  config = lib.mkIf cfg.enable {
    xdg = {
      enable = true;

      mimeApps = {
        enable = true;

        defaultApplications = { "image/*" = [ "org.gnome.Loupe.desktop" ]; };
      };
    };
    dconf = {
      enable = true;
      settings = {
        "org/gnome/mutter" = {
          auto-maximize = false;
          check-alive-timeout = "30000";
          experimental-features = [ "scale-monitor-framebuffer" ];
        };
        "org/gnome/desktop/interface" = { color-scheme = "prefer-dark"; };
        "org/gnome/desktop/wm/preferences" = {
          audible-bell = false;
          visual-bell = false;
        };
        "org/gnome/desktop/peripherals/keyboard" = {
          numlock-state = true;
          remember-numlock-state = true;
        };
      };
    };
  };
}
