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

  home.file = {
    ".config/kitty" = {
      source = ../../configs/kitty;
      recursive = true;
    };
  };
}
