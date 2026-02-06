{ self, ... }:
{
  flake.nixosModules.discord =
    { config, ... }:
    {
      home-manager.users.${config.meta.ryk.username}.imports = [ self.homeModules.discord ];
    };

  flake.homeModules.discord =
    { pkgs, ... }:
    {
      home.packages = [
        pkgs.discord
        pkgs.betterdiscordctl
      ];
    };
}
