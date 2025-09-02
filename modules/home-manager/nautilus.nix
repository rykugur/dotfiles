{ config, lib, pkgs, ... }:
let cfg = config.rhx.nautilus;
in {
  options.rhx.nautilus = {
    enable = lib.mkEnableOption "Enable nautilus home-manager module.";
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [ nautilus ];

    xdg = {
      enable = true;

      mimeApps = {
        enable = true;

        defaultApplications = {
          "inode/directory" = [ "org.gnome.Nautilus.desktop" ];
        };
      };
    };
  };
}
