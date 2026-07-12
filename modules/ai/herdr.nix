{ ... }:
{
  flake.modules.homeManager.herdr =
    { ... }:
    {
      # herdr's home-manager module ships with home-manager upstream
      # (programs.herdr). Enabling it installs the package and, if `settings`
      # is set, writes ~/.config/herdr/config.toml.
      programs.herdr.enable = true;
      programs.herdr.settings = {
        terminal.default_shell = "nu";
        ui = {
          pane_borders = true;
          pane_gaps = true;
        };
      };
    };
}
