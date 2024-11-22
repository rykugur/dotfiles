{ config, lib, pkgs, ... }:
let cfg = config.rhx.tmux;
in {
  options.rhx.tmux = {
    enable = lib.mkEnableOption "Enable tmux home-manager module.";
  };

  config = lib.mkIf cfg.enable {
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
}
