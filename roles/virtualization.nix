{ config, lib, pkgs, username, ... }:
let cfg = config.rhx.roles.virtualization;
in {
  options.rhx.roles.virtualization.enable =
    lib.mkEnableOption "Enable virtualization role";

  config = lib.mkIf cfg.enable {
    # enable nixOS modules for desktop role
    rhx = { virtman.enable = true; };

    # home-manager config
    home-manager.users.${username} = {
      # rhx = {};
      home.packages = with pkgs; [ lima ];
    };
  };
}
