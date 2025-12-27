{ config, lib, pkgs, username, ... }:
let cfg = config.ryk.roles.dev;
in {
  options.ryk.roles.dev.enable = lib.mkEnableOption "Enable dev role";

  config = lib.mkIf cfg.enable {
    # enable nixOS modules for desktop role
    # ryk = {};

    # home-manager config
    home-manager.users.${username} = {
      ryk = {
        atuin.enable = true;
        git = {
          enable = true;
          gitconfig.enable = true;
        };
        jujutsu.enable = true;
        zed-editor.enable = true;
      };

      home.packages = with pkgs; [
        just
        prettierd
        stylua
        vscode
        yaak
        bruno
        insomnia
      ];
    };
  };
}
