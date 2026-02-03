{ config, lib, pkgs, ... }:
let cfg = config.ryk.thunar;
in {
  options.ryk.thunar = {
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
