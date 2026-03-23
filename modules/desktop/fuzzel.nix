{ ... }:
{
  flake.modules.homeManager.fuzzel =
    { pkgs, ... }:
    {
      programs.fuzzel = {
        enable = true;
        settings = {
          # catppuccin mocha
          # TODO: can we make this better/use a fetcher?
          colors = {
            background = "1e1e2edd";
            text = "cdd6f4ff";
            match = "f38ba8ff";
            selection = "585b70ff";
            selection-match = "f38ba8ff";
            selection-text = "cdd6f4ff";
            border = "b4befeff";
          };
        };
      };
    };
}
