{ config, lib, pkgs, username, ... }:
let cfg = config.roles.dev;
in {
  options.roles.dev.enable = lib.mkEnableOption "Enable desktop role";

  config = lib.mkIf cfg.enable {
    home-manager.users.${username} = {
      home.packages = with pkgs; [ bruno direnv ];

      programs.fish = {
        enable = true;
        interactiveShellInit = ''
          eval (direnv hook fish)
        '';
      };
    };

  };
}
