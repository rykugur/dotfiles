{ config, lib, pkgs, username, ... }:
let cfg = config.rhx.roles.dev;
in {
  options.rhx.roles.dev.enable = lib.mkEnableOption "Enable dev role";

  config = lib.mkIf cfg.enable {
    # enable nixOS modules for desktop role
    # rhx = {};

    # home-manager config
    home-manager.users.${username} = {
      rhx = {
        atuin.enable = true;
        git = {
          enable = true;
          gitconfig.enable = true;
        };
        jujutsu.enable = true;
      };

      home.packages = with pkgs; [ bruno yaak ];
    };
  };
}
