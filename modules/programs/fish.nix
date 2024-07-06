{ config, lib, pkgs, username, ... }:
let cfg = config.modules.programs.fish;
in {
  options.modules.programs.fish.enable = lib.mkEnableOption "Enable fish.";

  config = lib.mkIf cfg.enable {
    modules.programs.oh-my-posh.enable = true;
    # config.modules.programs.starship.enable = true;

    programs.fish = {
      enable = true;
      vendor.functions.enable = true;
    };

    users.users.${username}.shell = pkgs.fish;

    home-manager.users.${username} = {
      home.packages = with pkgs; [
        babelfish

        fishPlugins.autopair
        fishPlugins.grc
        fishPlugins.fzf-fish
        fishPlugins.z
      ];

      programs.fish = {
        enable = true;
        interactiveShellInit = ''
          source ~/.dotfiles/configs/fish/config.fish
          oh-my-posh init fish | source
        '';
      };

      programs.fzf.enable = true;

      programs.zoxide = {
        enable = true;
        enableFishIntegration = true;
      };
    };
  };
}
