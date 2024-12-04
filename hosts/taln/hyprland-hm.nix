{
  monitor = "eDP-1,1920x1080@120,0x0,1";
  exec-once = [ "nm-applet" ];
  misc = { vrr = 2; };
  windowrulev2 = [
    "workspace 4 silent, class:(discord)"

    "workspace 5, class:(dota2)"
    "workspace 5, class:(Project Zomboid)"
    "fullscreen, class:(Project Zomboid)"
    "workspace 5, class:(X4)"
  ];
}
