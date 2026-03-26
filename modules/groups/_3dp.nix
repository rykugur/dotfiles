{ ... }:
{
  flake.modules.homeManager._3dp =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        qidi-slicer-bin
        freecad-wayland
      ];
    };
}
