{ ... }:
{
  flake.modules.homeManager.thunar =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [ xfce.thunar ];

      xdg = {
        enable = true;

        mimeApps = {
          enable = true;

          defaultApplications = { "inode/directory" = [ "thunar.desktop" ]; };
        };
      };
    };
}
