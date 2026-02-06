{ self, ... }:
{
  flake.nixosModules.flameshot =
    { config, ... }:
    {
      home-manager.users.${config.meta.ryk.username}.imports = [ self.homeModules.flameshot ];
    };

  flake.homeModules.flameshot =
    { ... }:
    {
      services.flameshot.enable = true;
    };
}
