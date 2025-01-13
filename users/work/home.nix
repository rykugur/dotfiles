# This is your home-manager configuration file
# Use this to configure your home environment (it replaces ~/.config/nixpkgs/home.nix)
{ outputs, pkgs, username, ... }: {
  imports = [ outputs.hmModules ];

  nixpkgs = {
    # You can add overlays here
    overlays = [
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
    fnm
    prettierd
    rbenv
    stylua
    tldr
    yarn

    nixd
    nixfmt-classic
    nix-index
  ];

  rhx = {
    fish.enable = true;
    ghostty.enable = true;
    git = {
      enable = true;
      gitconfig.enable = false;
    };
    kitty.enable = true;
    nushell.enable = true;
    nvim.enable = true;
    ranger.enable = true;
    # ssh.enable = true;
    starship.enable = true;
    # tmux.enable = true;
    zellij.enable = true;
  };

  ################## other stuff you shouldn't need to touch
  programs.home-manager.enable = true;

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "23.11";
}
