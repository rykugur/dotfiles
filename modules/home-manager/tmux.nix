{ puts, pkgs, ... }: {
  programs.tmux = {
    enable = true;

    baseIndex = 1;
    clock24 = true;
    escapeTime = 0;
    mouse = true;
    newSession = true;
    prefix = "C-b";

    extraConfig = ''
      set -g @catppuccin_flavour 'mocha' # latte, frappe, macchiato, mocha
    '';

    plugins = with pkgs; [
      tmuxPlugins.better-mouse-mode
      tmuxPlugins.catppuccin
      tmuxPlugins.sensible
      tmuxPlugins.yank
    ];
  };
}
