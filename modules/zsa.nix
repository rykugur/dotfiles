{ ... }:
{
  flake.nixosModules.zsa =
    { pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.keymapp ];

      hardware.keyboard.zsa.enable = true;
    };
}
