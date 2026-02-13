{ self, ... }:
{
  flake.nixosModules.winboat =
    { pkgs, ... }:
    {
      imports = [
        self.nixosModules.docker
      ];

      environment.systemPackages = [
        pkgs.winboat
        pkgs.freerdp
      ];
    };
}
