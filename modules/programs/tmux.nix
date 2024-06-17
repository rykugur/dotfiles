{ config, lib, pkgs, username, ... }:
let
  cfg = config.modules.programs.tmux;
  tmuxCfg = config.programs.tmux;
in {
  options.modules.programs.tmux.enable = lib.mkEnableOption "Enable tmux";

  config = lib.mkIf cfg.enable {
    home-manager.users.${username} = {
      programs.tmux = {
        enable = true;

        baseIndex = 1;
        clock24 = true;
        escapeTime = 0;
        keyMode = "vi";
        mouse = false;
        newSession = true;
        prefix = "C-b";
        terminal = "screen-256color";

        tmuxinator = { enable = true; };

        extraConfig = ''
          set -g @catppuccin_flavour 'mocha' # latte, frappe, macchiato, mocha
          set -g mouse-select-pane on

          bind | split-window -h
          bind _ split-window -v

          bind -N "Select pane to the left of the active pane" j select-pane -L
          bind -N "Select pane below the active pane" k select-pane -D
          bind -N "Select pane above the active pane" l select-pane -U
          bind -N "Select pane to the right of the active pane" \; select-pane -R

          bind -r -N "Resize the pane left by ${
            toString tmuxCfg.resizeAmount
          }" \
            j resize-pane -L ${toString tmuxCfg.resizeAmount}
          bind -r -N "Resize the pane down by ${
            toString tmuxCfg.resizeAmount
          }" \
            k resize-pane -D ${toString tmuxCfg.resizeAmount}
          bind -r -N "Resize the pane up by ${toString tmuxCfg.resizeAmount}" \
            l resize-pane -U ${toString tmuxCfg.resizeAmount}
          bind -r -N "Resize the pane right by ${
            toString tmuxCfg.resizeAmount
          }" \
            \; resize-pane -R ${toString tmuxCfg.resizeAmount}

          # bind r to re-source config
          # bind-key r source-file ~/.config/tmux/tmux.conf
          bind r source-file ~/.config/tmux/tmux.conf \; display "RELOADED"
        '';

        plugins = with pkgs; [
          tmuxPlugins.better-mouse-mode
          tmuxPlugins.catppuccin
          tmuxPlugins.sensible
          tmuxPlugins.vim-tmux-navigator
          tmuxPlugins.yank
        ];
      };

      home = {
        file = {
          ".config/tmuxinator" = {
            source = ../../configs/tmuxinator;
            recursive = true;
          };
        };
      };
    };
  };
}
