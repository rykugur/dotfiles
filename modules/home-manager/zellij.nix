{ config, inputs, lib, pkgs, ... }:
let
  cfg = config.rhx.zellij;
  zellij-autolock = pkgs.fetchurl {
    url =
      "https://github.com/fresh2dev/zellij-autolock/releases/download/0.2.1/zellij-autolock.wasm";
    sha256 = "sha256-3KvHgNdJdb8Nd83OxxrKFuzM6nAjn0G0wyebOI9zs40=";
  };
in {
  options.rhx.zellij = {
    enable = lib.mkEnableOption "Enable zellij home-manager module.";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ inputs.zjstatus.packages.${pkgs.system}.default ];

    programs.zellij = {
      enable = true;
      settings = {
        theme = "catppuccin-mocha";
        keybinds = {
          # bind = [ ];
          # TODO: find a different bind for this, conflicts with neovim pane movement
          unbind = [ "Ctrl h" ];
        };
        "autolock location=\"${
          builtins.unsafeDiscardStringContext zellij-autolock
        }\"" = {
          triggers =
            "nvim|vim|v|nv"; # Lock when any open these programs open. They are expected to unlock themselves when closed (e.g., using zellij.vim plugin).
          watch_triggers =
            "fzf|zoxide|atuin|atac"; # Lock when any of these open and monitor until closed.
          watch_interval = "1.0"; # When monitoring, check every X seconds.
        };
      };
    };
  };
}
