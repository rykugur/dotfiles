{ config, lib, username, ... }:
let cfg = config.modules.programs.term.zellij;
in {
  options.modules.programs.term.zellij.enable =
    lib.mkEnableOption "Enable zellij.";

  config = lib.mkIf cfg.enable {
    home-manager.users.${username} = {
      programs.zellij = {
        enable = true;
        settings = {
          theme = "catppuccin-mocha";
          keybinds = {
            # TODO: find a different bind for this, conflicts with neovim pane movement
            unbind = [ "Ctrl h" ];
          };
        };
      };
    };
  };
}
