{ outputs, pkgs, ... }: {
  imports = [
    outputs.homeManagerModules.starship
    outputs.homeManagerModules.tmux
  ];

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
    zoxide

    btop
    iotop
    iftop
    nvtop
  ];

  programs = {
    ssh = {
      enable = true;

      matchBlocks = {
        "jezrien taln tanavast" = {
          forwardAgent = true;
          extraOptions = {
            "IdentityAgent" = "~/.1password/agent.sock";
          };
        };
        "quadra" = {
          user = "quadra";
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
  };
}
