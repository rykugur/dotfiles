{ ... }:
{
  flake.modules.homeManager.herdr =
    { osConfig, ... }:
    let
      # herdr's default_shell wants a command name; ryk.defaultShell uses "nushell".
      shellCmd = {
        fish = "fish";
        nushell = "nu";
        bash = "bash";
      }.${osConfig.ryk.defaultShell or "nushell"};
    in
    {
      # herdr's home-manager module ships with home-manager upstream
      # (programs.herdr). Enabling it installs the package and, if `settings`
      # is set, writes ~/.config/herdr/config.toml.
      programs.herdr.enable = true;
      programs.herdr.settings = {
        terminal.default_shell = shellCmd;
        ui = {
          pane_borders = true;
          pane_gaps = true;
        };
      };
    };
}
