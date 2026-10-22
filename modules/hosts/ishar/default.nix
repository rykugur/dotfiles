# ishar — comin pilot container (x86_64-linux, Proxmox LXC on roshar).
# Deliberately minimal: its job is to prove pull-based deployment, not to run
# a workload.
{ inputs, self, ... }:
{
  imports = [ ./_image.nix ];

  flake.nixosConfigurations.ishar = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = [
      self.modules.nixos.nix-defaults
      self.modules.nixos.vasher-cache
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
      ./_role.nix
      ./_platform-lxc.nix
      ./_comin-branch.nix
    ];
    specialArgs = { inherit inputs; };
  };
}
