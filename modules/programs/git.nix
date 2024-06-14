{ config, lib, username, ... }:
let cfg = config.programs.gitz;
in {
  options.programs.gitz.enable = lib.mkEnableOption "enable git module";

  config = lib.mkIf cfg.enable {
    home-manager.users.${username} = {
      programs.git = {
        enable = true;
        userName = "Dusty";
        userEmail = "rollhax@gmail.com";
      };

      home.file.".gitconfig".source = ../../configs/gitconfig;
    };
  };
}
