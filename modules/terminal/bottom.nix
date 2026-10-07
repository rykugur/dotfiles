{ ... }:
{
  flake.modules.homeManager.bottom =
    { ... }:
    {
      programs.bottom = {
        enable = true;

        settings = {
          flags = {
            tree = true;
            group_processes = true;
          };
        };
      };
    };
}
