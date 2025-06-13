{ inputs, outputs, hostname, username, ... }: {
  ### system config
  imports = [
    inputs.home-manager.darwinModules.home-manager

    outputs.baseModules
    outputs.darwinModules
  ];

  nixpkgs = {
    overlays = [
      # If you want to use overlays exported from other flakes:
      # neovim-nightly-overlay.overlays.default
      outputs.overlays.additions
      outputs.overlays.modifications
    ];
  };

  users.users.${username} = { home = "/Users/${username}"; };

  security.pam.services.sudo_local.touchIdAuth = true;

  # Necessary for using flakes on this system.
  nix = {
    gc = {
      automatic = true;
      options = "--delete-older-than 10d";
    };

    optimise.automatic = true;

    settings = {
      experimental-features = "nix-command flakes pipe-operators";

      # TODO: find a better spot for this
      extra-substituters = [ "https://helix.cachix.org" ];
      extra-trusted-public-keys =
        [ "helix.cachix.org-1:ejp9KQpR1FBI2onstMQ34yogDm4OgU2ru6lIwPvuCVs=" ];
    };
  };

  system = {
    defaults = {
      dock = {
        autohide = true;

        show-recents = false;

        magnification = true;
        largesize = 64;
        tilesize = 48;
      };
      NSGlobalDomain = {
        ApplePressAndHoldEnabled = false;
        InitialKeyRepeat = 15;
        KeyRepeat = 2;
        NSWindowShouldDragOnGesture = true;
      };
    };

    primaryUser = username;
  };

  # services = { karabiner-elements = { enable = true; }; };

  # adding this here because nushell + nix-darwin is weird AF
  homebrew = {
    enable = true;

    brews = [
      { name = "kubectl"; }
      { name = "kubecolor"; }
      { name = "kubectx"; }
      { name = "helm"; }
      { name = "helmfile"; }
    ];

    onActivation = {
      autoUpdate = true;
      cleanup = "uninstall";
      upgrade = true;
    };
  };

  rhx = {
    # aerospace.enable = true;
    fonts.enable = true;
  };

  ### home-manager config

  home-manager = {
    extraSpecialArgs = { inherit inputs outputs hostname username; };
    users = { ${username} = import ./home.nix; };
    backupFileExtension = "bak";
  };

  ### stuff to mostly ignore

  # Set Git commit hash for darwin-version.
  system.configurationRevision =
    inputs.self.rev or inputs.self.dirtyRev or null;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 5;

  # The platform the configuration will be used on.
  nixpkgs.hostPlatform = "aarch64-darwin";
}
