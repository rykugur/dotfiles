{ ... }:
{
  flake.modules.homeManager._3dp =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        freecad-wayland
        orca-slicer
        qidi-slicer-bin
      ];
    };
}
