{ ... }:
{
  flake.modules.homeManager.btop =
    { ... }:
    {
      # TODO: would be cool to genericize this
      programs.btop = {
        enable = true;

        settings = { theme_background = false; };
      };
    };
}
