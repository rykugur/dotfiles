{ self, withSystem, ... }:
{
  flake.nixosModules.audiorelay =
    { config, ... }:
    let
      metaCfg = config.meta.ryk;
    in
    {
      home-manager.users.${metaCfg.username}.imports = [ self.homeModules.audiorelay ];
    };

  flake.homeModules.audiorelay =
    { pkgs, ... }:
    let
      audiorelayPkg = withSystem pkgs.stdenv.hostPlatform.system (
        { config, ... }: config.packages.audiorelay
      );
    in
    {
      home.packages = [ audiorelayPkg ];
    };
}
