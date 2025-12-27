{ config, lib, pkgs, username, ... }:
let cfg = config.ryk.roles._3dp;
in {
  options.ryk.roles._3dp.enable = lib.mkEnableOption "Enable 3dp role";

  config = lib.mkIf cfg.enable {
    # enable nixOS modules for desktop role
    # ryk = { };

    # home-manager config
    home-manager.users.${username} = {
      home.packages = with pkgs; [ qidi-slicer-bin freecad-wayland ];
    };
  };
}
