{ pkgs, username, ... }: {
  imports = [ ../../home ];

  home = {
    inherit username;
    homeDirectory = "/Users/${username}";
  };

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
    oh-my-posh.enable = true;
    ssh.enable = true;
    # starship.enable = true;
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
