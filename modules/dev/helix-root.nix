{ self, ... }:
{
  # Enable the shared Helix Home Manager module for root on NixOS hosts.
  # Import alongside whatever enables Helix for the primary user.
  flake.modules.nixos.helix-root =
    { config, lib, ... }:
    let
      username = config.ryk.username;
      primaryStateVersion =
        config.home-manager.users.${username}.home.stateVersion or "23.11";
    in
    {
      home-manager.users.root = {
        imports = [ self.modules.homeManager.helix ];

        home = {
          username = "root";
          homeDirectory = "/root";
          stateVersion = lib.mkDefault primaryStateVersion;
        };
      };
    };
}
