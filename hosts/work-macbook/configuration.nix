{ inputs, outputs, lib, config, pkgs, hostname, roles, ... }:
let username = "dustin.jerome";
in {
  imports = [ inputs.home-manager.darwinModules.home-manager ];

  environment.systemPackages = [ pkgs.nixfmt-classic ];

  # home-manager = {
  #   extraSpecialArgs = { inherit inputs outputs hostname username; };
  #   users = { ${username} = import ../../users/work/home.nix; };
  #   backupFileExtension = "bak";
  # };

  security.pam.enableSudoTouchIdAuth = true;

  # Set Git commit hash for darwin-version.
  system.configurationRevision =
    inputs.self.rev or inputs.self.dirtyRev or null;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 5;

  # The platform the configuration will be used on.
  nixpkgs.hostPlatform = "aarch64-darwin";
}
