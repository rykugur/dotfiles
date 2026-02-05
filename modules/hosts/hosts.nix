{
  withSystem,
  inputs,
  self,
  ...
}:
{
  flake.nixosConfigurations = {
    jezrien = withSystem "x86_64-linux" (
      { ... }:
      inputs.nixpkgs.lib.nixosSystem {
        modules = [
          self.nixosModules.meta
          self.nixosModules.jezrien-config
        ];
      }
    );
  };
}
