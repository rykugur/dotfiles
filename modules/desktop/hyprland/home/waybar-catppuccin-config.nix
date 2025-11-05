{
  layer = "top";
  position = "top";
  modules-left = [ "hyprland/workspaces" ];
  modules-center = [ "custom/music" ];
  modules-right = [
    "pulseaudio"
    # "backlight"
    # "battery"
    "clock"
    "tray"
    "custom/lock"
    # "custom/power"
  ];
  "hyprland/workspaces" = {
    on-click = "activate";
    format = "{icon}";
    format-icons = {
      default = "";
      "1" = "1";
      "2" = "2";
      "3" = "3";
      "4" = "4";
      "5" = "5";
      active = "󱓻";
    };
  };
  tray = {
    icon-size = 21;
    spacing = 10;
  };
  "custom/music" = {
    format = "  {}";
    escape = true;
    interval = 5;
    tooltip = false;
    exec = "playerctl metadata --format='{{ title }}'";
    on-click = "playerctl play-pause";
    max-length = 50;
  };
  clock = {
    timezone = "America/Chicago";
    tooltip-format = ''
      <big>{=%Y %B}</big>
      <tt><small>{calendar}</small></tt>'';
    format-alt = " {=%d/%m/%Y}";
    format = " {=%H=%M}";
  };

  backlight = {
    device = "intel_backlight";
    format = "{icon}";
    format-icons = [ "" "" "" "" "" "" "" "" "" ];
  };
  battery = {
    states = {
      warning = 30;
      critical = 15;
    };
    format = "{icon}";
    format-charging = "";
    format-plugged = "";
    format-alt = "{icon}";
    format-icons = [ "" "" "" "" "" "" "" "" "" "" "" "" ];
  };
  pulseaudio = {
    # "scroll-step"= 1; # %; can be a float
    format = "{icon} {volume}%";
    format-muted = "";
    format-icons = { "default" = [ "" "" " " ]; };
    on-click = "pavucontrol";
  };
  "custom/lock" = {
    tooltip = false;
    # on-click = "sh -c '(sleep 0.5s; swaylock --grace 0)' & disown";
    on-click = "wlogout &";
    format = "";
  };
  # "custom/power" = {
  #   tooltip = false;
  #   on-click = "wlogout &";
  #   format = "襤";
  # };
}
