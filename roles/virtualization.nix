{ config, lib, pkgs, username, ... }:
let cfg = config.ryk.roles.virtualization;
in {
  options.ryk.roles.virtualization.enable =
    lib.mkEnableOption "Enable virtualization role";

  config = lib.mkIf cfg.enable {
    # enable nixOS modules for desktop role
    ryk = {
      distrobox.enable = true;
      virtman.enable = true;
    };

    # home-manager config
    home-manager.users.${username} = {
      # ryk = {};
      home.packages = with pkgs; [ lima minikube ];
    };
  };
}
