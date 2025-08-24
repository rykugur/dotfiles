{ ... }:
let ghosttyCmd = "ghostty --gtk-single-instance=true";
in {
  layer = "top";
  position = "top";
  spacing = 0;
  height = 26;
  modules-left = [ "hyprland/workspaces" ];
  modules-center = [ "clock" ];
  modules-right = [
    "tray"
    # "custom/dropbox"
    # "bluetooth"
    "network"
    "wireplumber"
    "cpu"
    "power-profiles-daemon"
    # "battery"
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
    persistent-workspaces = {
      "1" = [ ];
      "2" = [ ];
      "3" = [ ];
      "4" = [ ];
      "5" = [ ];
    };
  };
  cpu = {
    interval = 5;
    format = "󰍛";
    on-click = "${ghosttyCmd} -e btop";
  };
  clock = {
    format = "{:%A %I:%M %p}";
    format-alt = "{:%d %B W%V %Y}";
    tooltip = false;
  };
  network = {
    format-icons = [ "󰤯" "󰤟" "󰤢" "󰤥" "󰤨" ];
    format = "{icon}";
    format-wifi = "{icon}";
    format-ethernet = "󰀂";
    format-disconnected = "󰖪";
    tooltip-format-wifi = ''
      {essid} ({frequency} GHz)
      ⇣{bandwidthDownBytes}  ⇡{bandwidthUpBytes}'';
    tooltip-format-ethernet = "⇣{bandwidthDownBytes}  ⇡{bandwidthUpBytes}";
    tooltip-format-disconnected = "Disconnected";
    interval = 3;
    nospacing = 1;
    on-click = "${ghosttyCmd} -e nmcli";
  };
  battery = {
    interval = 5;
    format = "{capacity}% {icon}";
    format-discharging = "{icon}";
    format-charging = "{icon}";
    format-plugged = "";
    format-icons = {
      charging = [ "󰢜" "󰂆" "󰂇" "󰂈" "󰢝" "󰂉" "󰢞" "󰂊" "󰂋" "󰂅" ];
      default = [ "󰁺" "󰁻" "󰁼" "󰁽" "󰁾" "󰁿" "󰂀" "󰂁" "󰂂" "󰁹" ];
    };
    format-full = "Charged ";
    tooltip-format-discharging = "{power:>1.0f}W↓ {capacity}%";
    tooltip-format-charging = "{power:>1.0f}W↑ {capacity}%";
    states = {
      warning = 20;
      critical = 10;
    };
  };
  bluetooth = {
    format = "󰂯";
    format-disabled = "󰂲";
    format-connected = "";
    tooltip-format = "Devices connected: {num_connections}";
    on-click = "blueberry";
  };
  wireplumber = {
    # Changed from "pulseaudio"
    "format" = "";
    format-muted = "󰝟";
    scroll-step = 5;
    on-click = "pavucontrol";
    tooltip-format = "Playing at {volume}%";
    on-click-right =
      "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"; # Updated command
    # max-volume = 150; # Optional: allow volume over 100%
  };
  tray = { spacing = 13; };
  power-profiles-daemon = {
    format = "{icon}";
    tooltip-format = "Power profile: {profile}";
    tooltip = true;
    format-icons = {
      power-saver = "󰡳";
      balanced = "󰊚";
      performance = "󰡴";
    };
  };
  # "custom/dropbox" = {
  #   format = "";
  #   on-click = "nautilus ~/Dropbox";
  #   exec = "dropbox-cli status";
  #   return-type = "text";
  #   interval = 5;
  #   tooltip = true;
  #   tooltip-format = "{}";
  # };
}
