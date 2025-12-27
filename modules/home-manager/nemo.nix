{ config, lib, pkgs, ... }:
let cfg = config.ryk.nemo;
in {
  options.ryk.nemo = {
    enable = lib.mkEnableOption "Enable nemo home-manager module.";
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [ nemo ];

    xdg = {
      enable = true;

      mimeApps = {
        enable = true;

        defaultApplications = { "inode/directory" = [ "nemo.desktop" ]; };
      };
    };
  };
}
