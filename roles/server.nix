{ config, lib, username, ... }:
let cfg = config.ryk.roles.server;
in {
  options.ryk.roles.server.enable = lib.mkEnableOption "Enable server role";

  config = lib.mkIf cfg.enable {
    # enable nixOS modules for desktop role
    # ryk = {};

    # home-manager config
    home-manager.users.${username} = {
      # ryk = {};
    };
  };
}
