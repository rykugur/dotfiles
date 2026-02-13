{ config, lib, ... }:
let cfg = config.ryk.git;
in {
  options.ryk.git = {
    enable = lib.mkEnableOption "Enable git home-manager module.";
    gitconfig.enable = lib.mkEnableOption "Use hm-managed gitconfig";
  };

  config = lib.mkIf cfg.enable {
    programs = {
      git = {
        enable = true;

        settings = {
          user = {
            name = "Dusty";
            email = "rollhax@gmail.com";
          };
        };

        lfs = { enable = true; };
      };

      diff-so-fancy = {
        enable = true;
        enableGitIntegration = true;
      };

      gh = {
        enable = true;
        settings = { git_protocol = "ssh"; };
      };

    };

    home.file.".gitconfig" =
      lib.mkIf cfg.gitconfig.enable { source = ../../configs/gitconfig; };
  };
}
