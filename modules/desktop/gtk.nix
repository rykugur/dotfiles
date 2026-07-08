{ ... }:
{
  flake.modules.homeManager.gtk =
    { config, lib, pkgs, ... }:
    {
      dconf = lib.mkIf pkgs.stdenv.isLinux {
        enable = true;
        # re-enable middle-click primary-selection paste (ships off by default)
        settings."org/gnome/desktop/interface".gtk-enable-primary-paste = true;
      };

      # stylix sets the x11/gtk cursor sub-enables but not the top-level
      # home.pointerCursor.enable that gates all cursor generation, so nothing
      # gets applied and cursors fall back to the default X theme.
      home.pointerCursor.enable = lib.mkIf ((config.stylix.cursor or null) != null) true;
    };
}
