{ ... }:
{
  flake.modules.homeManager.swappy =
    { ... }:
    {
      home.file = {
        ".config/swappy" = {
          source = ../../configs/swappy;
          recursive = true;
        };
      };
    };
}
