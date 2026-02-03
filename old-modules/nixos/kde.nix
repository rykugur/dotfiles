{ config, lib, pkgs, ... }:
let cfg = config.ryk.kde;
in {
  options.ryk.kde.enable = lib.mkEnableOption "Enable kde nixOS module";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      (pkgs.catppuccin-sddm.override {
        flavor = "mocha";
        font = "ZedMono";
        fontSize = "9";
        # background = "${./wallpaper.png}";
        loginBackground = true;
      })
      (pkgs.catppuccin-kde.override { flavour = [ "mocha" ]; })
      pkgs.catppuccin-cursors.mochaBlue
    ];

    # programs.seahorse.enable = false;

    # workaround for error: "The option `programs.ssh.askPassword' has conflicting definition values:" when seahorse (gnome) is also enabled.
    programs.ssh.askPassword =
      pkgs.lib.mkForce "${pkgs.kdePackages.ksshaskpass}/bin/ksshaskpass";

    services = {
      power-profiles-daemon = { enable = true; };

      xserver.enable = true;

      displayManager.sddm = {
        enable = true;
        autoNumlock = true;
        # theme = "catppuccin-mocha";
      };
      desktopManager.plasma6.enable = true;
    };
  };
}
