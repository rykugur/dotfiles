{ ... }:
{
  flake.modules.homeManager.herdr =
    { config, lib, osConfig, ... }:
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
        keys = {
          previous_tab = "prefix+h";
          next_tab = "prefix+l";
          focus_pane_left = "prefix+shift+h";
          focus_pane_down = "prefix+shift+j";
          focus_pane_up = "prefix+shift+k";
          focus_pane_right = "prefix+shift+l";
        };
      };

      # Keep the OMP lifecycle extension in lockstep with the configured Herdr binary.
      # `herdr integration install omp` errors out if the extensions dir is missing,
      # which aborts the whole activation under `set -e`; create it first so the
      # integration installs cleanly on hosts where omp hasn't been run yet.
      home.activation.installHerdrOmpIntegration = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        run mkdir -p ${config.home.homeDirectory}/.omp/agent/extensions
        run ${config.programs.herdr.package}/bin/herdr integration install omp
      '';
    };
}
