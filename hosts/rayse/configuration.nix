{ inputs, outputs, pkgs, hostname, username, ... }: {
  ### system config
  imports = [ inputs.home-manager.darwinModules.home-manager ];

  users.users.${username} = { home = "/Users/${username}"; };

  security.pam.enableSudoTouchIdAuth = true;

  # Necessary for using flakes on this system.
  nix.settings.experimental-features = "nix-command flakes pipe-operators";

  ### home-manager config

  home-manager = {
    extraSpecialArgs = { inherit inputs outputs hostname username; };
    # TODO: may need a separate macbook user?
    # or just move in-line for now?
    users = { ${username} = import ../../users/tmp-rayse/home.nix; };
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
