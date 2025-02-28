{ inputs, outputs, pkgs, hostname, username, ... }: {
  ### system config
  imports = [ inputs.home-manager.darwinModules.home-manager ];

  environment.systemPackages = [ pkgs.nixfmt-classic ];

  users.users.${username} = { home = "/Users/${username}"; };

  security.pam.services.sudo_local.touchIdAuth = true;

  # TODO: find a better spot for this
  nix.settings = {
    extra-substituters = ["https://helix.cachix.org"];
    extra-trusted-public-keys = ["helix.cachix.org-1:ejp9KQpR1FBI2onstMQ34yogDm4OgU2ru6lIwPvuCVs="];
  };

  # workaround
  ids.gids.nixbld = 30000;

  # Necessary for using flakes on this system.
  nix.settings.experimental-features = "nix-command flakes pipe-operators";

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
