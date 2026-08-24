{ self, ... }:
{
  flake.modules.homeManager._3dp =
    { pkgs, ... }:
    {
      home.packages = [
        pkgs.freecad-wayland
        pkgs.orca-slicer
        pkgs.qidi-slicer-bin
        self.packages.${pkgs.stdenv.hostPlatform.system}.bambu-studio
      ];
    };
}
