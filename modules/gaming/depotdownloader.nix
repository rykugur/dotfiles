{ ... }:
{
  # DepotDownloader + the `depot-fill` nushell helper that wraps it. See
  # Arcanum: wiki/Reference/Slow Steam Downloads.md for why this exists
  # (Steam-for-Linux client-side download throttle, upstream #13024).
  flake.modules.homeManager.depotdownloader =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.depotdownloader ];

      # nushell vendor autoload: available in every shell whenever this
      # module is imported, regardless of which nushell config sources it.
      # xdg.dataFile (not home.file) so this respects $XDG_DATA_HOME like
      # nushell's own $nu.data-dir does, instead of hardcoding ~/.local/share.
      xdg.dataFile."nushell/vendor/autoload/depot-fill.nu".source = ./depot-fill.nu;
    };
}
