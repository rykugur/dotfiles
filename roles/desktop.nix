{ config, lib, username, ... }:
let cfg = config.rhx.roles.desktop;
in {
  options.rhx.roles.desktop.enable = lib.mkEnableOption "Enable desktop role";

  config = lib.mkIf cfg.enable {
    # enable nixOS modules for desktop role
    rhx = {
      roles = {
        # force enable dev role - all of my desktops are dev machines too
        dev.enable = true;
        # force enable terminal role
        terminal.enable = true;
      };

      _1password.enable = true;
      fonts.enable = true;
      pipewire.enable = true;
      ssh.enable = true;

      # DE stuff
      hyprland.enable = true;
      # kde.enable = true;
      # gnome.enable = true;
    };

    # home-manager config
    home-manager.users.${username} = {
      rhx = {
        browser.enable = true;
        easyeffects.enable = true;
        hyprland.enable = true;
        homelab.enable = true;
        ssh.enable = true;
      };
    };
  };
}
