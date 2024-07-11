{ config, lib, pkgs, username, ... }:
let cfg = config.modules.wm.kde;
in {
  options.modules.wm.kde.enable = lib.mkEnableOption "Enable KDE WM.";

  config = lib.mkIf cfg.enable {

    services.desktopManager.plasma6.enable = true;

    qt = {
      enable = true;
      platformTheme = "gnome";
      style = "adwaita-dark";
    };

    programs.dconf.enable = true;

    programs.ssh.askPassword =
      lib.mkForce "${pkgs.kdePackages.ksshaskpass.out}/bin/ksshaskpass";

    home-manager.users.${username} = { };
  };
}
