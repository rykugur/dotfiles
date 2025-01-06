{ config, lib, pkgs, ... }:
let cfg = config.rhx.gnome;
in {
  options.rhx.gnome.enable = lib.mkEnableOption "Enable gnome nixOS module";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      gnome-tweaks

      gnomeExtensions.dash-to-dock
    ];

    services.xserver = {
      enable = true;
      displayManager.gdm.enable = true;
      desktopManager.gnome.enable = true;
    };
  };
}
