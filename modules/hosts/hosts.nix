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
        modules = with self.nixosModules; [
          jezrien-config
          jezrien-hardware

          meta
          {
            meta.ryk.username = "dusty";
            meta.ryk.hostname = "jezrien";
          }
        ];
      }
    );
  };
}
