{ config, lib, username, ... }:
let cfg = config.rhx.roles.vr;
in {
  options.rhx.roles.vr.enable = lib.mkEnableOption "Enable vr role";

  config = lib.mkIf cfg.enable {
    # enable nixOS modules for desktop role
    # rhx = {};

    # home-manager config
    home-manager.users.${username} = { };
  };
}
