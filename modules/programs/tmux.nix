{ config, lib, username, ... }:
let cfg = config.modules.programs.tmux;
in {
  options.modules.programs.tmux.enable = lib.mkEnableOption "Enable tmux";

  config = lib.mkIf cfg.enable {
    home-manager.users.${username} = {
      # TODO: better understand this, appears to be required to get the HM config
      config, pkgs, ... }: {
        home.packages = [ pkgs.sesh pkgs.tmux pkgs.tmuxifier pkgs.tpm ];

        home.file = {
          ".config/tmux" = {
            source = config.lib.file.mkOutOfStoreSymlink
              "${config.home.homeDirectory}/.dotfiles/configs/tmux";
            recursive = true;
          };
          ".tmux/plugins/tpm" = { source = "${pkgs.tpm}"; };
        };
      };
  };
}
