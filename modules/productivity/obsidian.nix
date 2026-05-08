{ ... }:
{
  flake.modules.homeManager.obsidian =
    { ... }:
    {
      programs.obsidian = {
        enable = true;
        cli.enable = true;
      };
    };
}
