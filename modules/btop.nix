{ self, ... }:
{
  flake.nixosModules.btop =
    { config, ... }:
    {
      home-manager.users.${config.meta.ryk.username}.imports = [ self.homeModules.btop ];
    };

  flake.homeModules.btop =
    { ... }:
    {
      programs.btop = {
        enable = true;

        settings = {
          theme_background = false;
        };
      };
    };
}
