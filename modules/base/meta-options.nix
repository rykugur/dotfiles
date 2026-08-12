{ ... }:
{
  flake.modules.nixos.meta =
    { lib, ... }:
    {
      options.ryk = {
        username = lib.mkOption {
          type = lib.types.str;
          default = "dusty";
          description = "Primary user account name";
        };

        desktop.compositor = lib.mkOption {
          type = lib.types.nullOr (
            lib.types.enum [
              "hyprland"
              "niri"
            ]
          );
          default = null;
          description = ''
            Wayland compositor owning the graphical session. Set by the compositor
            module; bars read it to pick their WM-specific integration instead of
            reaching into another compositor's options.
          '';
        };
      };
    };
}
