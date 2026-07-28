{ ... }:
{
  flake.modules.homeManager._3dp =
    { config, lib, pkgs, ... }:
    {
      options.ryk.printing3d.enableBambuStudio = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Whether to install Bambu Studio.";
      };

      config.home.packages = with pkgs;
        [
          freecad-wayland
          orca-slicer
          qidi-slicer-bin
        ]
        ++ lib.optionals config.ryk.printing3d.enableBambuStudio [ bambu-studio ];
    };
}
