{ ... }: {
  ryk.hyprland = {
    enable = true;
    bar = "dankMaterialShell";
    layout = "scrolling";
    monitors =
      [ "DP-1,3440x1440@175,0x1440,1" "DP-2,3440x1440@144,0x0,1,vrr,0" ];

    workspaces = [
      "1,monitor:DP-2"
      "2,monitor:DP-2"
      "3,monitor:DP-1"
      "4,monitor:DP-1"
      "5,monitor:DP-1"
    ];
  };
}
