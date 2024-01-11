{ pkgs, ... }: {
  home.packages = with pkgs; [
    babelfish
    duf
    eza
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

    fishPlugins.tide
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
    plugins = [
      { name = "tide"; src = pkgs.fishPlugins.tide; }
    ];
  };

  home.file = {
    # ".config/fish/config.fish" = {
    #   source = ../../../configs/fish/config.fish;
    # };
    # ".config/fish/fish_plugins" = {
    #   source = ../../../configs/fish/fish_plugins;
    # };
    ".config/kitty" = {
      source = ../../configs/kitty;
      recursive = true;
    };
  };
}
