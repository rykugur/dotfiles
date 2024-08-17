{ config, lib, pkgs, username, ... }:
let cfg = config.modules.programs.git;
in {
  options.modules.programs.git.enable = lib.mkEnableOption "enable git module";

  config = lib.mkIf cfg.enable {
    home-manager.users.${username} = {
      programs = {
        git = {
          enable = true;
          userName = "Dusty";
          userEmail = "rollhax@gmail.com";
        };
        gh.enable = true;
      };

      home.file.".gitconfig".source = ../../configs/gitconfig;
    };
  };
}
