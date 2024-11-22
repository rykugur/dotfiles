{ config, lib, pkgs, ... }:
let cfg = config.rhx.git;
in {
  options.rhx.git = {
    enable = lib.mkEnableOption "Enable git home-manager module.";
  };

  config = lib.mkIf cfg.enable {
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
}
