{ config, lib, pkgs, username, ... }:
let cfg = config.rhx.roles._3dp;
in {
  options.rhx.roles._3dp.enable = lib.mkEnableOption "Enable 3dp role";

  config = lib.mkIf cfg.enable {
    # enable nixOS modules for desktop role
    # rhx = { };

    # home-manager config
    home-manager.users.${username} = {
      home.packages = with pkgs; [ orca-slicer super-slicer freecad-wayland ];
    };
  };
}
