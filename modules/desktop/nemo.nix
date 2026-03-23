{ ... }:
{
  flake.modules.homeManager.nemo =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [ nemo ];

      xdg = {
        enable = true;

        mimeApps = {
          enable = true;

          defaultApplications = { "inode/directory" = [ "nemo.desktop" ]; };
        };
      };
    };
}
