{ config, inputs, outputs, pkgs, username, ... }: {
  imports = [
    outputs.hmModules

    inputs.sops-nix.homeManagerModules.sops
  ];

  nixpkgs = {
    overlays = [ outputs.overlays.additions outputs.overlays.modifications ];
    config = {
      allowUnfree = true;
      # Workaround for https://github.com/nix-community/home-manager/issues/2942
      allowUnfreePredicate = _: true;
      # workaround for obsidian
      permittedInsecurePackages = [ "electron-25.9.0" ];
    };
  };

  home = {
    inherit username;
    homeDirectory = "/Users/${username}";
  };

  home.packages = with pkgs; [
    nh

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

  sops.age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";

  # TODO: these are in roles/terminal but that is failing on nix-darwin
  # will remove these once I figure that out
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
  programs.carapace.enable = true;
  programs.zoxide.enable = true;

  rhx = {
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
    homelab.enable = true; # dunno why this doesn't work on macOS
    nushell.enable = true;
    ssh.enable = true;
    starship.enable = true;
    yazi.enable = true;
    zellij.enable = true;
  };

  # also requires XDG_CONFIG_HOME to be set!
  xdg.enable = true;

  ################## other stuff you shouldn't need to touch
  programs.home-manager.enable = true;

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "23.11";
}
