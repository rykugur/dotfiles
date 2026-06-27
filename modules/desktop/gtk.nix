{ ... }:
{
  flake.modules.homeManager.gtk =
    { lib, pkgs, ... }:
    {
      dconf = lib.mkIf pkgs.stdenv.isLinux {
        enable = true;
        # re-enable middle-click primary-selection paste (ships off by default)
        settings."org/gnome/desktop/interface".gtk-enable-primary-paste = true;
      };
    };
}
