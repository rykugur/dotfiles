{ config, lib, username, ... }:
let cfg = config.modules.programs.swappy;
in {
  options.modules.programs.swappy.enable = lib.mkEnableOption "Enable swappy";

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
