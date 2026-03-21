{ ... }:
{
  flake.modules.homeManager.ccstatusline =
    { ... }:
    {
      home.file = {
        ".config/ccstatusline" = {
          source = ../../configs/ccstatusline;
          recursive = true;
        };
      };
    };
}
