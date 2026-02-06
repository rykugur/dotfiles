{ ... }:
{
  flake.nixosModules.winboat =
    { pkgs, ... }:
    {
      ryk.virtualization.docker.enable = true;

      environment.systemPackages = [
        pkgs.winboat
        pkgs.freerdp
      ];
    };
}
