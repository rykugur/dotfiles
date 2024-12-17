{ config, lib, pkgs, ... }:
let cfg = config.rhx.thunar;
in {
  options.rhx.thunar = {
    enable = lib.mkEnableOption "Enable thunar home-manager module.";
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [ xfce.thunar ];

    xdg = {
      enable = true;

      mimeApps = {
        enable = true;

        defaultApplications = { "inode/directory" = [ "thunar.desktop" ]; };
      };
    };
  };
}
