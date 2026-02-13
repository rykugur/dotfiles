{
  inputs',
  self,
  ...
}:
{
  flake.nixosModules.audiorelay =
    { config, ... }:
    let
      metaCfg = config.meta.ryk;
    in
    {
      # TODO: open firewall ports 59100 tcp/udp
      home-manager.users.${metaCfg.username}.imports = [ self.homeModules.audiorelay ];
    };

  flake.homeModules.audiorelay =
    { ... }:
    {
      home.packages = [ inputs'.ryze312-stackpkgs.packages.audiorelay ];
    };
}
