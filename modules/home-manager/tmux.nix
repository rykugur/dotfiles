{ config, inputs, pkgs, ... }:
let
  cfg = config.programs.tmux;
in
{
  programs.tmux = {
    enable = true;

    baseIndex = 1;
    clock24 = true;
    escapeTime = 0;
    keyMode = "vi";
    mouse = true;
    newSession = true;
    prefix = "C-b";
    terminal = "screen-256color";

    tmuxinator = {
      enable = true;
    };

    extraConfig = ''
      set -g @catppuccin_flavour 'mocha' # latte, frappe, macchiato, mocha

      bind | split-window -h
      bind _ split-window -v

      bind -N "Select pane to the left of the active pane" j select-pane -L
      bind -N "Select pane below the active pane" k select-pane -D
      bind -N "Select pane above the active pane" l select-pane -U
      bind -N "Select pane to the right of the active pane" \; select-pane -R

      bind -r -N "Resize the pane left by ${toString cfg.resizeAmount}" \
        H resize-pane -L ${toString cfg.resizeAmount}
      bind -r -N "Resize the pane down by ${toString cfg.resizeAmount}" \
        J resize-pane -D ${toString cfg.resizeAmount}
      bind -r -N "Resize the pane up by ${toString cfg.resizeAmount}" \
        K resize-pane -U ${toString cfg.resizeAmount}
      bind -r -N "Resize the pane right by ${toString cfg.resizeAmount}" \
        L resize-pane -R ${toString cfg.resizeAmount}
      # bind r to re-source config
      # bind-key r source-file ~/.config/tmux/tmux.conf
      bind r source-file ~/.config/tmux/tmux.conf \; display "RELOADED"
    '';

    plugins = with pkgs; [
      tmuxPlugins.better-mouse-mode
      tmuxPlugins.catppuccin
      tmuxPlugins.sensible
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
}
