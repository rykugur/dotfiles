{ ... }:
{
  flake.modules.homeManager.herdr =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      herdrNavigatorPlugin = "${pkgs.herdr-navigator}/share/herdr/plugins/herdr-navigator";
    in
    {
      # herdr's home-manager module ships with home-manager upstream
      # (programs.herdr). `settings` is deliberately unset: it writes
      # ~/.config/herdr/config.toml as a read-only store symlink, and herdr
      # must be able to rewrite that file at runtime (dismissing onboarding
      # fails with "Read-only file system (os error 30)" otherwise). Point it
      # at the tracked dotfile instead; herdr writes through the symlink, so
      # runtime changes land in the repo.
      programs.herdr.enable = true;
      xdg.configFile."herdr/config.toml".source =
        config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/configs/herdr/config.toml";

      # Keep the OMP lifecycle extension in lockstep with the configured Herdr binary.
      # `herdr integration install omp` errors out if the extensions dir is missing,
      # which aborts the whole activation under `set -e`; create it first so the
      # integration installs cleanly on hosts where omp hasn't been run yet.
      home.activation.installHerdrOmpIntegration = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        run mkdir -p ${config.home.homeDirectory}/.omp/agent/extensions
        run ${config.programs.herdr.package}/bin/herdr integration install omp
      '';

      # Build the navigator with Nix, then register its immutable plugin root.
      # `plugin link` is idempotent and updates the registered store path.
      home.activation.installHerdrNavigatorPlugin = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        run ${config.programs.herdr.package}/bin/herdr plugin link ${herdrNavigatorPlugin} --enabled
      '';
    };
}
