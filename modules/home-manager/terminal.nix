{ pkgs, ... }: {
  home.packages = with pkgs; [
    duf
    eza
    fzf
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
  ];

  programs.starship = {
    enable = true;
    enableFishIntegration = false;
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
