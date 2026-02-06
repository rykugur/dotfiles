{ self, ... }:
{
  flake.nixosModules.swappy =
    { config, ... }:
    {
      home-manager.users.${config.meta.ryk.username}.imports = [ self.homeModules.swappy ];
    };

  flake.homeModules.swappy =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.swappy ];

      home.file = {
        ".config/swappy" = {
          source = ../configs/swappy;
          recursive = true;
        };
      };
    };
}
