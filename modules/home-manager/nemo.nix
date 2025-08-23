{ config, lib, pkgs, ... }:
let cfg = config.rhx.nemo;
in {
  options.rhx.nemo = {
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
