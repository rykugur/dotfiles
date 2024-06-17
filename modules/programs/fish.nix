{ config, lib, pkgs, username, ... }:
let cfg = config.modules.programs.fish;
in {
  options.modules.programs.fish.enable = lib.mkEnableOption "Enable fish.";

  config = lib.mkIf cfg.enable {
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
        '';
      };
    };
  };
}
