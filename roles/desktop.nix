{ config, lib, username, outputs, ... }:
let cfg = config.ryk.roles.desktop;
in {
  imports = [ outputs.modules.nixos.ssh ];

  options.ryk.roles.desktop.enable = lib.mkEnableOption "Enable desktop role";

  config = lib.mkIf cfg.enable {
    # enable nixOS modules for desktop role
    ryk = {
      roles = {
        # force enable dev role - all of my desktops are dev machines too
        dev.enable = true;
        # force enable terminal role
        terminal.enable = true;
      };

      _1password.enable = true;
      # ssh.enable removed — handled by nixos.ssh import above
    };

    # home-manager config
    home-manager.users.${username} = {
      imports = with outputs.modules.homeManager; [
        zen-browser
        homelab
        # ssh imported transitively via nixos.ssh
      ];
    };
  };
}
