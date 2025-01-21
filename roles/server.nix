{ config, lib, username, ... }:
let cfg = config.rhx.roles.server;
in {
  options.rhx.roles.server.enable = lib.mkEnableOption "Enable server role";

  config = lib.mkIf cfg.enable {
    # enable nixOS modules for desktop role
    # rhx = {};

    # home-manager config
    home-manager.users.${username} = {
      # rhx = {};
    };
  };
}
