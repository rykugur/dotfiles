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
    warp-terminal

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

    matchBlocks = {
      "jezrien taln tanavast" = {
        forwardAgent = true;
        extraOptions = {
          "IdentityAgent" = "~/.1password/agent.sock";
        };
      };
    };
  };

  home = {
    file = {
      ".config/kitty" = {
        source = ../../configs/kitty;
        recursive = true;
      };
    };

    # sessionVariables = {
    #   SSH_AUTH_SOCK = "~/.1password/agent.sock";
    # };
  };
}
