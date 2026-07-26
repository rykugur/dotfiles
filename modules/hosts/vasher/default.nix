{ inputs, self, ... }:
{
  imports = [ ./_image.nix ];

  flake.nixosConfigurations.vasher = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = [
      self.modules.nixos.nix-defaults
      ./_role.nix
      ./_platform-lxc.nix
    ];
    specialArgs = { inherit inputs; };
  };
}
