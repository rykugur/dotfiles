# This is your home-manager configuration file
# Use this to configure your home environment (it replaces ~/.config/nixpkgs/home.nix)
{ config, inputs, outputs, pkgs, username, ... }: {
  imports = [
    outputs.hmModules

    inputs.sops-nix.homeManagerModules.sops
  ];

  nixpkgs = {
    # You can add overlays here
    overlays = [
      outputs.overlays.modifications
      # If you want to use overlays exported from other flakes:
      # neovim-nightly-overlay.overlays.default

      # Or define it inline, for example:
      # (final: prev: {
      #   hi = final.hello.overrideAttrs (oldAttrs: {
      #     patches = [ ./change-hello-to-hi.patch ];
      #   });
      # })
    ];
    # Configure your nixpkgs instance
    config = {
      # Disable if you don't want unfree packages
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
    _1password-cli
    bat
    just
    nh
    prettierd
    rbenv
    stylua
    tldr

    nixd
    nixfmt-classic
    nix-index
  ];

  sops = {
    defaultSopsFile = ../../hosts/work-macbook/secrets.yaml;

    age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";

    secrets.ssh_private_key = {
      path = "${config.home.homeDirectory}/.ssh/id_ed25519";
      mode = "0400";
    };
  };

  # TODO: these are in roles/terminal but that is failing on nix-darwin
  # will remove these once I figure that out
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
  programs.carapace.enable = true;
  programs.zoxide.enable = true;

  rhx = {
    # fish.enable = true;
    git = {
      enable = true;
      gitconfig.enable = false;
    };
    jujutsu.enable = true;

    # kitty.enable = true;
    helix.enable = true;
    nvim.enable = true;

    ghostty.enable = true;
    nushell.enable = true;
    starship.enable = true;
    tmux.enable = true;
    yazi.enable = true;
    zellij.enable = true;
  };

  xdg.enable = true;

  ################## other stuff you shouldn't need to touch
  programs.home-manager.enable = true;

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "23.11";
}
