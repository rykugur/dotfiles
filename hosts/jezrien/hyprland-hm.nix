{
  monitor = [ "DP-1,3440x1440@175,0x1440,1" "DP-2,3440x1440@144,0x0,1" ];
  exec-once = [
    "solaar -w hide"
    # needs to happen after ags
    "corectrl --minimize-systray"
  ];
  misc = { vrr = 2; };
  workspace = [
    "1,monitor:DP-1"
    "2,monitor:DP-1"
    "3,monitor:DP-1"
    "4,monitor:DP-1"
    "5,monitor:DP-1"
    "6,monitor:DP-2"
    "7,monitor:DP-2"
  ];
  windowrulev2 = [
    "workspace 6 silent, class:(discord)"

    "workspace 5, class:(dota2)"
    "workspace 5, class:(Project Zomboid)"
    "fullscreen, class:(Project Zomboid)"
    "workspace 5, class:(X4)"
  ];
}
