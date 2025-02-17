{ config, lib, ... }:
let cfg = config.rhx.git;
in {
  options.rhx.git = {
    enable = lib.mkEnableOption "Enable git home-manager module.";
    gitconfig.enable = lib.mkEnableOption "Use hm-managed gitconfig";
  };

  config = lib.mkIf cfg.enable {
    programs = {
      git = {
        enable = true;
        userName = "Dusty";
        userEmail = "rollhax@gmail.com";

        diff-so-fancy = { enable = true; };
      };

      gh.enable = true;
    };

    home.file.".gitconfig" =
      lib.mkIf cfg.gitconfig.enable { source = ../../configs/gitconfig; };
  };
}
