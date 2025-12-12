{ ... }: {
  rhx.niri = {
    enable = true;
    bar = "dankMaterialShell";
    monitors = {
      "DP-1" = {
        mode = {
          width = 3440;
          height = 1440;
          refresh = 174.963;
        };
        position = {
          x = 0;
          y = 1440;
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
          y = 0;
        };
      };
    };
    touch = {
      input = "HDMI-A-1";
      rotation = "90";
    };

  };
}
