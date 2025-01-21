{ config, lib, username, ... }:
let cfg = config.rhx.roles.terminal;
in {
  options.rhx.roles.terminal.enable = lib.mkEnableOption "Enable terminal role";

  config = lib.mkIf cfg.enable {
    # enable nixOS modules for desktop role
    # rhx = { };

    # home-manager config
    home-manager.users.${username} = {
      rhx = {
        ghostty.enable = true;
        nushell.enable = true;
        nvim.enable = true;
        starship.enable = true;
        wezterm.enable = true;
        yazi.enable = true;
        zellij.enable = true;
      };
    };
  };
}
