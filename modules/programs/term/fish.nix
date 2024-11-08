{ config, lib, pkgs, username, ... }:
let cfg = config.modules.programs.term.fish;
in {
  options.modules.programs.term.fish.enable = lib.mkEnableOption "Enable fish.";

  config = lib.mkIf cfg.enable {
    modules.programs.term.oh-my-posh.enable = true;

    programs.fish = {
      enable = true;
      vendor.functions.enable = true;
    };

    users.users.${username}.shell = pkgs.fish;

    home-manager.users.${username} = {
      home.packages = with pkgs; [
        babelfish

        grc

        fishPlugins.autopair
        fishPlugins.grc
        fishPlugins.fzf-fish
        fishPlugins.z
      ];

      programs.fish = {
        enable = true;
        interactiveShellInit = ''
          source ~/.dotfiles/configs/fish/config.fish
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
