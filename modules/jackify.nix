{ self, withSystem, ... }:
{
  flake.nixosModules.jackify =
    { config, ... }:
    let
      metaCfg = config.meta.ryk;
    in
    {
      home-manager.users.${metaCfg.username}.imports = [ self.homeModules.jackify ];
    };

  flake.homeModules.jackify =
    { pkgs, ... }:
    let
      jackifyPkg = withSystem pkgs.stdenv.hostPlatform.system ({ config, ... }: config.packages.jackify);
    in
    {
      home.packages = [ jackifyPkg ];
    };
}
