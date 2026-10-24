# Throwaway VM testing comin deployments across Btrfs root rollback.
{ inputs, self, ... }:
{
  imports = [ ./_installer.nix ];

  flake.nixosConfigurations.rysn = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = [
      self.modules.nixos.nix-defaults
      self.modules.nixos.vasher-cache
      self.modules.nixos.pve-vm
      self.modules.nixos.meta
      self.modules.nixos.helix-guest
      self.modules.nixos.comin
      ./_disko.nix
      ./_impermanence.nix
      ./_role.nix
      { ryk.comin.branch = "rysn-impermanence"; }
    ];
    specialArgs = { inherit inputs; };
  };
}
