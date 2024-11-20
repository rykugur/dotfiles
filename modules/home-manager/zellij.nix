{ config, lib, ... }:
let cfg = config.rhx.zellij;
in {
  options.rhx.zellij = {
    enable = lib.mkEnableOption "Enable fish home-manager module.";
  };

  config = lib.mkIf cfg.enable {
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
}
