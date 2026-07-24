{ ... }:
{
  flake.modules.homeManager.starsector =
    { pkgs, ... }:
    {
      home.packages = [
        pkgs.starsector
        pkgs.trios
      ];
    };
}
