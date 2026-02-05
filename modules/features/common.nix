{ self, ... }:
{
  flake.nixosModules.features-common =
    { ... }:
    {
      imports = [
        self.nixosModules.helix
      ];
    };
}
