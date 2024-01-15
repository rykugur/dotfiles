{ pkgs, ... }: {
  home.packages = with pkgs; [
    babelfish
    duf
    eza
    grc
    jq
    kitty
    lm_sensors
    pciutils
    ripgrep
    silver-searcher
    tree
    usbutils

    btop
    iotop
    iftop
    nvtop

    fishPlugins.autopair
    fishPlugins.grc
    fishPlugins.fzf-fish
    fishPlugins.tide
    fishPlugins.z
  ];

  programs.starship = {
    enable = true;
    enableFishIntegration = false;
  };

  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      source ~/.dotfiles/configs/fish/config.fish
    '';
  };

  programs.ssh = {
    enable = true;
    forwardAgent = true;
    extraConfig = ''
      	IdentityAgent ~/.1password/agent.sock
    '';
  };

  home.file = {
    ".config/kitty" = {
      source = ../../configs/kitty;
      recursive = true;
    };
  };
}
