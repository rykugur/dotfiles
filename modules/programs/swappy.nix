{ config, lib, username, ... }:
let cfg = config.programs.swappy;
in {
  options.programs.swappy.enable = lib.mkEnableOption "Enable swappy";

  config = lib.mkIf cfg.enable {
    home-manager.users.${username} = {
      home.file = {
        ".config/swappy" = {
          source = ../../configs/swappy;
          recursive = true;
        };
      };
    };
  };
}
