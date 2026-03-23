{ ... }:
{
  flake.modules.homeManager.nautilus =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [ nautilus ];

      xdg = {
        enable = true;

        mimeApps = {
          enable = true;

          defaultApplications = {
            "inode/directory" = [ "org.gnome.Nautilus.desktop" ];
          };
        };
      };
    };
}
