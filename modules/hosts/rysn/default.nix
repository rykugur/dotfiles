# Throwaway VM for testing Btrfs root rollback before introducing comin.
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
      ./_disko.nix
      ./_impermanence.nix
      ./_role.nix
    ];
    specialArgs = { inherit inputs; };
  };
}
