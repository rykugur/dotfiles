{ config, lib, pkgs, ... }:
let cfg = config.rhx.gnome;
in {
  options.rhx.gnome.enable = lib.mkEnableOption "Enable gnome nixOS module";

  config = lib.mkIf cfg.enable {
    modules.wm.gtk.enable = true;

    environment.systemPackages = with pkgs; [
      gnome-tweaks

      gnomeExtensions.dash-to-dock
    ];

    services.xserver = {
      enable = true;
      displayManager.gdm.enable = true;
      desktopManager.gnome.enable = true;
    };

    # this is required I guess
    hardware.pulseaudio.enable = false;
  };
}
