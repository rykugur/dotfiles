{ ... }:
{
  flake.modules.homeManager.jackify =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.jackify ];
    };
}
