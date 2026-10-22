# nale — comin pilot VM (x86_64-linux, QEMU guest on roshar).
# Installed once with nixos-anywhere + disko; every change after that arrives
# through comin.
{ inputs, self, ... }:
{
  imports = [ ./_installer.nix ];

  flake.nixosConfigurations.nale = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = [
      self.modules.nixos.nix-defaults
      self.modules.nixos.vasher-cache
      self.modules.nixos.pve-vm
      inputs.home-manager.nixosModules.home-manager
      {
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          extraSpecialArgs = { inherit inputs; };
          users.dusty = {
            imports = with self.modules.homeManager; [
              helix
              helix-lxc
            ];
            home.stateVersion = "26.05";
          };
        };
      }
      self.modules.nixos.comin
      ./_disko.nix
      ./_role.nix
      ./_comin-branch.nix
      # ./_impermanence.nix — only after comin is proven without it
    ];
    specialArgs = { inherit inputs; };
  };
}
