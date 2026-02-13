{ pkgs, outputs, ... }: {
  imports = [
    ../../home

    # TODO: fix this later; shared modules across nixos/nix-darwin can be painful
    ../../legacy-modules/home-manager/carapace.nix
    ../../legacy-modules/home-manager/direnv.nix
    ../../legacy-modules/home-manager/ghostty.nix
    ../../legacy-modules/home-manager/git.nix
    ../../legacy-modules/home-manager/helix.nix
    ../../legacy-modules/home-manager/homelab.nix
    ../../legacy-modules/home-manager/jujutsu.nix
    ../../legacy-modules/home-manager/ssh.nix
    ../../legacy-modules/home-manager/starship.nix
    ../../legacy-modules/home-manager/yazi.nix
    ../../legacy-modules/home-manager/zellij.nix
    ../../legacy-modules/home-manager/zoxide.nix

    # Dendritic modules
    outputs.modules.homeManager.nushell
  ];

  # home = {
  #   inherit username;
  #   homeDirectory = "/Users/${username}";
  # };

  home.packages = with pkgs; [
    nh
    nix-prefetch-scripts

    _1password-cli
    bat
    docker
    fd
    fzf
    just
    silver-searcher
    stylua
    tldr
  ];

  ryk = {
    # TODO: these are in roles/terminal but that is failing on nix-darwin
    # will remove these once I figure that out
    direnv.enable = true;
    carapace.enable = true;
    zoxide.enable = true;

    # aerospace.enable = true;
    git = {
      enable = true;
      gitconfig.enable = true;
    };
    jujutsu.enable = true;
    helix.enable = true;
    # zed-editor.enable = true;

    # atuin.enable = true;
    ghostty.enable = true;
    homelab.enable = true;
    ssh.enable = true;
    starship.enable = true;
    yazi.enable = true;
    zellij.enable = true;
  };

  ################## other stuff you shouldn't need to touch
  programs.home-manager.enable = true;

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "23.11";
}
