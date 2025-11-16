{ pkgs, ... }: {
  imports = [
    ../../home

    # TODO: fix this later; shared modules across nixos/nix-darwin can be painful
    ../../modules/home-manager/carapace.nix
    ../../modules/home-manager/direnv.nix
    ../../modules/home-manager/ghostty.nix
    ../../modules/home-manager/git.nix
    ../../modules/home-manager/helix.nix
    ../../modules/home-manager/homelab.nix
    ../../modules/home-manager/jujutsu.nix
    ../../modules/home-manager/nushell.nix
    ../../modules/home-manager/ssh.nix
    ../../modules/home-manager/starship.nix
    ../../modules/home-manager/yazi.nix
    ../../modules/home-manager/zellij.nix
    ../../modules/home-manager/zoxide.nix
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

  rhx = {
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
    nushell.enable = true;
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
