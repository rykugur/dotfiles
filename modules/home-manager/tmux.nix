{ puts, pkgs, ... }: {
  programs.tmux = {
    enable = true;
    shortcut = "a";
    # aggressiveResize = true; -- Disabled to be iTerm-friendly
    baseIndex = 1;
    newSession = true;
    # Stop tmux+escape craziness.
    escapeTime = 0;
    # Force tmux to use /tmp for sockets (WSL2 compat)
    secureSocket = false;

    plugins = with pkgs; [
      tmuxPlugins.better-mouse-mode
      tmuxPlugins.catppuccin
      tmuxPlugins.sensible
      tmuxPlugins.yank
    ];
  };

  home.file = {
    ".tmux.conf" = {
      source = ../../configs/tmux/tmux.conf;
    };
  };
}
