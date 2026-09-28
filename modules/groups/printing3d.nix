{ self, ... }:
{
  flake.modules.homeManager._3dp =
    { pkgs, ... }:
    {
      home.packages = [
        pkgs.freecad-wayland

        self.packages.${pkgs.stdenv.hostPlatform.system}.bambu-studio
        pkgs.qidi-slicer-bin
      ];

      xdg.mimeApps = {
        enable = true;
        defaultApplications = {
          "model/3mf" = [ "bambu-studio.desktop" ];
          "application/vnd.ms-3mfdocument" = [ "bambu-studio.desktop" ];
        };
      };
    };
}
