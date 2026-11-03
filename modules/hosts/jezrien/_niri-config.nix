{ ... }:
{
  ryk.niri = {
    # Geometry is unchanged: DP-2 sits directly above DP-1. Only the origin
    # moved. Wine's Wayland driver defines the primary display as the output
    # at exactly (0,0) and offsets the rest from it
    # (dlls/winewayland.drv/display.c, output_info_cmp_primary_x_y) - wl_output
    # has no primary flag - so DP-1 must be the origin for Wine apps to see the
    # AW3423DW and its 174.963Hz as primary.
    monitors = {
      "DP-1" = {
        mode = {
          width = 3440;
          height = 1440;
          refresh = 174.963;
        };
        position = {
          x = 0;
          y = 0;
        };
        variable-refresh-rate = "on-demand";
        focus-at-startup = true;
      };
      "DP-2" = {
        mode = {
          width = 3440;
          height = 1440;
          refresh = 144.0;
        };
        position = {
          x = 0;
          y = -1440;
        };
      };
    };

    touch = {
      input = "HDMI-A-1";
      rotation = "90";
    };
  };
}
