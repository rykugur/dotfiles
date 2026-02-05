{ self, ... }:
{
  flake.nixosModules.eve-online =
    { config, ... }:
    let
      metaCfg = config.meta.ryk;
    in
    {
      home-manager.users.${metaCfg.username}.imports = [ self.homeModules.eve-online ];
    };

  flake.homeModules.eve-online =
    { pkgs, ... }:
    {
      home.packages = [
        pkgs.pyfa
        # rift-intel-tool
      ];
    };
}
