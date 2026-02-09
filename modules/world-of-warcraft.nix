{ self, ... }:
let
  moduleName = "world-of-warcraft";
in
{
  flake.nixosModules.${moduleName} =
    { config, ... }:
    {
      home-manager.users.${config.meta.ryk.username}.imports = [ self.homeModules.${moduleName} ];
    };

  flake.homeModules.${moduleName} =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.wowup-cf ];
    };
}
