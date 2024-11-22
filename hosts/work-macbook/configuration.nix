{ inputs, outputs, lib, config, pkgs, hostname, username, ... }: {
  ### system config
  imports = [
    inputs.home-manager.darwinModules.home-manager

    # outputs.nixosModules
    outputs.hmModules
    # roles
  ];

  environment.systemPackages = [ pkgs.nixfmt-classic ];

  users.users.${username} = { home = "/Users/${username}"; };

  security.pam.enableSudoTouchIdAuth = true;

  ### home-manager config

  home-manager = {
    # extraSpecialArgs = { inherit inputs outputs hostname username; };
    extraSpecialArgs = { inherit inputs outputs hostname username; };
    users = { ${username} = import ../../users/work/home.nix; };
    backupFileExtension = "bak";
  };

  ### roles and modules

  # roles = { dev.enable = true; };

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
