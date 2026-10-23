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
      self.modules.nixos.meta
      self.modules.nixos.helix-guest
      self.modules.nixos.comin
      ./_role.nix
      ./_platform-lxc.nix
    ];
    specialArgs = { inherit inputs; };
  };
}
