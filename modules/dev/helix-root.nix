{ self, ... }:
{
  # Enable the shared Helix Home Manager module for root on NixOS hosts.
  # Import alongside whatever enables Helix for the primary user.
  flake.modules.nixos.helix-root =
    { lib, ... }:
    {
      home-manager.users.root = {
        imports = [ self.modules.homeManager.helix ];

        home = {
          username = "root";
          homeDirectory = "/root";
          stateVersion = lib.mkDefault "24.11";
        };
      };
    };
}
