{ config, lib, pkgs, ... }:
let cfg = config.ryk.tmux;
in {
  options.ryk.tmux = {
    enable = lib.mkEnableOption "Enable tmux home-manager module.";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      pkgs.sesh
      pkgs.tmux
      pkgs.tmuxifier
      pkgs.tmuxPlugins.sensible
      pkgs.tmuxPlugins.yank
    ];

    programs.tmux = {
      enable = true;

      baseIndex = 1;
      clock24 = true;
      escapeTime = 0;
      mouse = true;

      shell = "${pkgs.nushell}/bin/nu";
      terminal = ",xterm-256color:Tc";

      plugins = with pkgs.tmuxPlugins; [ sensible yank ];

      extraConfig = ''
        set -g status-keys vi
        set -g mode-keys   vi
        set -g status-position   top

        unbind C-b
        set -g prefix C-b
        bind -N "Send the prefix key through to the application" \
          C-b send-prefix

        set -g @catppuccin_flavour 'mocha' # latte, frappe, macchiato, mocha
        set -g @catppuccin_window_left_separator ""
        set -g @catppuccin_window_right_separator " "
        set -g @catppuccin_window_middle_separator " █"
        set -g @catppuccin_window_number_position "right"

        set -g @catppuccin_window_default_fill "number"
        set -g @catppuccin_window_default_text "#W"

        set -g @catppuccin_window_current_fill "number"
        set -g @catppuccin_window_current_text "#W"

        set -g @catppuccin_status_modules_right "directory user host session"
        set -g @catppuccin_status_left_separator  " "
        set -g @catppuccin_status_right_separator ""
        set -g @catppuccin_status_fill "icon"
        set -g @catppuccin_status_connect_separator "no"

        set -g @catppuccin_directory_text "#{pane_current_path}"

        bind-key | split-window -h
        bind-key _ split-window -v

        bind-key h select-window -t -1
        bind-key l select-window -t +1
        bind-key H swap-window -t -1
        bind-key L swap-window -t +1

        unbind-key r
        bind-key r source-file ~/.config/tmux/tmux.conf \; display "RELOADED"

        bind-key "s" run-shell "sesh connect \"$(
        	sesh list | fzf-tmux -p 55%,60% \
        		--no-sort --ansi --border-label ' sesh ' --prompt '⚡  ' \
        		--header '  ^a all ^t tmux ^g configs ^x zoxide ^d tmux kill ^f find' \
        		--bind 'tab:down,btab:up' \
        		--bind 'ctrl-a:change-prompt(⚡  )+reload(sesh list)' \
        		--bind 'ctrl-t:change-prompt(🪟  )+reload(sesh list -t)' \
        		--bind 'ctrl-g:change-prompt(⚙️  )+reload(sesh list -c)' \
        		--bind 'ctrl-x:change-prompt(📁  )+reload(sesh list -z)' \
        		--bind 'ctrl-f:change-prompt(🔎  )+reload(fd -H -d 2 -t d -E .Trash . ~)' \
        		--bind 'ctrl-d:execute(tmux kill-session -t {})+change-prompt(⚡  )+reload(sesh list)'
        )\""

        bind-key x kill-pane # skip "kill-pane 1? (y/n)" prompt
        set -g detach-on-destroy off  # don't exit from tmux when closing a session
      '';
    };
  };
}
