{ inputs, self, ... }:
{
  # Every headless guest in this flake (LXC or VM) wants the same editor, so
  # this bundles home-manager, the shared Helix config and the no-Wayland
  # overrides behind a single import instead of repeating the block per host.
  # Hosts that keep their own home-manager settings still merge cleanly.
  flake.modules.nixos.helix-guest =
    { config, lib, ... }:
    {
      # `meta` (for `ryk.username`) comes from the host's module list, as on
      # jezrien and hoid: importing it here too would double-declare the
      # option, since these module values carry no key to dedupe on.
      imports = [ inputs.home-manager.nixosModules.home-manager ];

      # Helix comes from its own flake input, not nixpkgs, so without this a
      # guest compiles it from source — minutes of Rust on a 4-core container.
      nix.settings = {
        substituters = [ "https://helix.cachix.org" ];
        trusted-public-keys = [
          "helix.cachix.org-1:ejp9KQpR1FBI2onstMQ34yogDm4OgU2ru6lIwPvuCVs="
        ];
      };

      home-manager = {
        useGlobalPkgs = lib.mkDefault true;
        useUserPackages = lib.mkDefault true;
        extraSpecialArgs = { inherit inputs; };

        users.${config.ryk.username} = {
          imports = with self.modules.homeManager; [
            helix
            helix-lxc
          ];
          # Follow the host unless it says otherwise.
          home.stateVersion = lib.mkDefault config.system.stateVersion;
        };
      };
    };
}
