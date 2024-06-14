{ config, lib, pkgs, username, ... }:
let cfg = config.programs.kitty;
in {
  options.programs.kitty.enable = lib.mkEnableOption "Enable kitty";

  config = lib.mkIf cfg.enable {
    home-manager.users.${username} = {
      home.packages = with pkgs; [ kitty ];

      home.file = {
        ".config/kitty" = {
          source = ../../configs/kitty;
          recursive = true;
        };
      };
    };
  };
}
