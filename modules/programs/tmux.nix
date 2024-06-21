{ config, lib, pkgs, username, ... }:
let
  cfg = config.modules.programs.tmux;
  tmuxCfg = config.programs.tmux;
in {
  options.modules.programs.tmux.enable = lib.mkEnableOption "Enable tmux";

  config = lib.mkIf cfg.enable {
    home-manager.users.${username} = {
      # programs.tmux = {
      #   enable = true;
      #
      #   baseIndex = 1;
      #   clock24 = true;
      #   escapeTime = 0;
      #   keyMode = "vi";
      #   mouse = false;
      #   newSession = true;
      #   prefix = "C-b";
      #   terminal = "screen-256color";
      #
      #   extraConfig = ''
      #     set -g @catppuccin_flavour 'mocha' # latte, frappe, macchiato, mocha
      #     set -g @catppuccin_window_left_separator ""
      #     set -g @catppuccin_window_right_separator " "
      #     set -g @catppuccin_window_middle_separator " █"
      #     set -g @catppuccin_window_number_position "right"
      #
      #     set -g @catppuccin_window_default_fill "number"
      #     set -g @catppuccin_window_default_text "#W"
      #
      #     set -g @catppuccin_window_current_fill "number"
      #     set -g @catppuccin_window_current_text "#W"
      #
      #     set -g @catppuccin_status_modules_right "directory user host session"
      #     set -g @catppuccin_status_left_separator  " "
      #     set -g @catppuccin_status_right_separator ""
      #     set -g @catppuccin_status_fill "icon"
      #     set -g @catppuccin_status_connect_separator "no"
      #
      #     set -g @catppuccin_directory_text "#{pane_current_path}"
      #
      #     set -g mouse on
      #     set -g status-position top
      #
      #     bind-key | split-window -h
      #     bind-key _ split-window -v
      #
      #     bind-key -n 'C-j' if-shell "$is_vim" 'send-keys C-j'  'select-pane -L'
      #     bind-key -n 'C-k' if-shell "$is_vim" 'send-keys C-k'  'select-pane -D'
      #     bind-key -n 'C-l' if-shell "$is_vim" 'send-keys C-l'  'select-pane -U'
      #     bind-key -n 'C-;' if-shell "$is_vim" 'send-keys C-;'  'select-pane -R'
      #
      #     # bind r to re-source config
      #     unbind-key r
      #     bind-key r source-file ~/.config/tmux/tmux.conf \; display "RELOADED"
      #   '';
      #
      #   plugins = with pkgs; [
      #     # tmuxPlugins.better-mouse-mode
      #     tmuxPlugins.catppuccin
      #     # tmuxPlugins.sensible
      #     tmuxPlugins.vim-tmux-navigator
      #     tmuxPlugins.yank
      #   ];
      # };

      home.packages = [ pkgs.tmux pkgs.tmuxifier pkgs.tpm ];

      home.file = { ".tmux/plugins/tpm" = { source = "${pkgs.tpm}"; }; };
    };
  };
}
