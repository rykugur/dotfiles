{ pkgs, ... }: {
  home.packages = with pkgs; [
    babelfish
    
    fishPlugins.autopair
    fishPlugins.grc
    fishPlugins.fzf-fish
    fishPlugins.tide
    fishPlugins.z
  ];
  
  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      source ~/.dotfiles/configs/fish/config.fish
    '';
  };
}
