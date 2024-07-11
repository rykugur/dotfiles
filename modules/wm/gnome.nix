{ config, lib, pkgs, username, ... }:
let cfg = config.modules.wm.gnome;
in {
  options.modules.wm.gnome.enable = lib.mkEnableOption "Enable Gnome WM.";

  config = lib.mkIf cfg.enable {
    modules.wm.gtk.enable = true;

    environment.systemPackages = with pkgs; [
      gnome.gnome-tweaks

      gnomeExtensions.dash-to-dock
    ];

    services.xserver = {
      enable = true;
      # displayManager.gdm.enable = true;
      desktopManager.gnome.enable = true;
    };

    # this is required I guess
    hardware.pulseaudio.enable = false;

    home-manager.users.${username} = {
      dconf.settings = {
        "org/gnome/mutter" = {
          auto-maximize = false;
          check-alive-timeout = "30000";
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
