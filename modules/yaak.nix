{ self, ... }:
{
  flake.nixosModules.yaak =
    { config, ... }:
    let
      metaCfg = config.meta.ryk;
      username = metaCfg.username;
    in
    {
      home-manager.users.${username}.imports = [ self.homeModules.yaak ];
    };

  flake.homeModules.yaak =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.yaak ];
    };
}
