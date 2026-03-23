{ ... }:
{
  flake.modules.homeManager.discord =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.discord pkgs.betterdiscordctl ];
    };
}
