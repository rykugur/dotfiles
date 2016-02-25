#!/bin/bash

function get_current_desktop_num {
  # wmctrl -d | wc -l
  xprop -root _NET_CURRENT_DESKTOP | cut -d' ' -f3
}

function get_num_desktops {
  # wmctrl -d | grep "*" | cut -d' ' -f1
  xprop -root _NET_NUMBER_OF_DESKTOPS | cut -d' ' -f3
}

function get_desktop_name {
  xprop -root _NET_DESKTOP_NAMES | cut -d'=' -f2 | cut -d',' -f$1 | sed -e 's/\"//g' | sed -e 's/\ //g'
}

export SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [ $(pgrep -c lemonbar_panel) -gt 1 ] ; then
	printf "%s\n" "The panel is already running." >&2
	exit 1
fi

trap 'trap - TERM; kill 0' INT TERM QUIT EXIT

. $SCRIPT_DIR/lemonbar_config.sh

# PANEL_SEP=" "
# PANEL_SEP_ELLIPSIS=""
# ICON_CPU="" # tachometer
# ICON_MEMORY=""
# ICON_DISK="" # bar chart
# ICON_DISK_ALT="" # bank
# ICON_BATTERY_0=""
# ICON_BATTERY_0_ALT="" # ambulance
# ICON_BATTERY_25=""
# ICON_BATTERY_50=""
# ICON_BATTERY_75=""
# ICON_BATTERY_100=""
# ICON_CALENDAR=""
# ICON_CLOCK=""
# ICON_CODE="" # github
# ICON_GAME=""
# ICON_FIREFOX=""
# ICON_NETWORK_ETH="" # cloud
# ICON_NETWORK_WIFI=""
# ICON_TERM="" # ">_"
# ICON_VOLUME=""
# ICON_VOLUME_LOW=""
# ICON_VOLUME_MUTE=""
# ICON_WORKSPACES=""
# COLOR_FOREGROUND='#FFEBDBB2'
# COLOR_BACKGROUND='#FF282828'
# COLOR_ACTIVE_MONITOR_FG='#FFEBDBB2'
# COLOR_ACTIVE_MONITOR_BG='#FF282828'
# COLOR_INACTIVE_MONITOR_FG='#FFEBDBB2'
# COLOR_INACTIVE_MONITOR_BG='#FF34322E'
# COLOR_FOCUSED_OCCUPIED_FG='#FFEBDBB2'
# COLOR_FOCUSED_OCCUPIED_BG='#FF282828'
# COLOR_FOCUSED_FREE_FG='#FF28211C'
# COLOR_FOCUSED_FREE_BG='#FF98971A'
# COLOR_FOCUSED_URGENT_FG='#FF28211C'
# COLOR_FOCUSED_URGENT_BG='#FFD79921'
# COLOR_OCCUPIED_FG='#FFEBDBB2'
# COLOR_OCCUPIED_BG='#FF282828'
# COLOR_FREE_FG='#FF28211C'
# COLOR_FREE_BG='#FF98971A'
# COLOR_URGENT_FG='#FF28211C'
# COLOR_URGENT_BG='#FFD79921'
# COLOR_LAYOUT_FG='#FFEBDBB2'
# COLOR_LAYOUT_BG='#FF282828'
# COLOR_TITLE_FG='#FFEBDBB2'
# COLOR_TITLE_BG='#FF282828'
# COLOR_STATUS_FG='#FFEBDBB2'
# COLOR_STATUS_BG='#FF282828'

while :; do
  DESKTOP_1="$ICON_TERM misc"
  DESKTOP_2="$ICON_FIREFOX www"
  DESKTOP_3="$ICON_GAME game"
  DESKTOP_4="$ICON_CODE code"

  CURR_DESKTOP_NUM=$(get_current_desktop_num)
  if [ $CURR_DESKTOP_NUM = "0" ]; then
    DESKTOP_1="$DESKTOP_1 ***"
  elif [ $CURR_DESKTOP_NUM = "1" ]; then
    DESKTOP_2="$DESKTOP_2 ***"
  elif [ $CURR_DESKTOP_NUM = "2" ]; then
    DESKTOP_3="$DESKTOP_3 ***"
  elif [ $CURR_DESKTOP_NUM = "3" ]; then
    DESKTOP_4="$DESKTOP_4 ***"
  fi

  WORKSPACES="$DESKTOP_1 $DESKTOP_2 $DESKTOP_3 $DESKTOP_4"
  
  BATTERY_STATUS=$(cat /sys/class/power_supply/BAT1/status)
  if [ $BATTERY_STATUS = "Discharging" ]; then
    CURR_BATTERY_PERCENT=$(acpi | awk '{print $4}' | sed -e 's/,//g' | sed -e 's/%//g')

    if [ $CURR_BATTERY_PERCENT -lt 10 ]; then
      ICON_BATTERY="$ICON_BATTERY_0_ALT"
    elif [ $CURR_BATTERY_PERCENT -lt 25 ]; then 
      ICON_BATTERY="$ICON_BATTERY_25"
    elif [ $CURR_BATTERY_PERCENT -lt 50 ]; then
      ICON_BATTERY="$ICON_BATTERY_50"
    elif [ $CURR_BATTERY_PERCENT -lt 75 ]; then
      ICON_BATTERY="$ICON_BATTERY_75"
    else
      ICON_BATTERY="$ICON_BATTERY_100"
    fi

    BATTERY="$ICON_BATTERY $CURR_BATTERY_PERCENT%"
  else
    BATTERY=""
  fi

  CURR_VOL_PERCENT=$(pactl list sinks | egrep "Volume.*\%" | head -n1 | awk '{print $5}')
  VOL="$ICON_VOLUME $CURR_VOL_PERCENT"

	NETWORK_ICON="$ICON_NETWORK_ETH" # default to ethernet icon
  IP_ADDR=$(ip addr show $DEFAULT_NETWORK_INTERFACE | awk '/inet / {print $2}' | sed -e 's/\/[0-9]*//g')
  NETWORK="$NETWORK_ICON $IP_ADDR"

  # DATE="$ICON_CALENDAR $(date +'%m.%d')"
  DATE="$(date +'%m.%d')"

  TIME="$(date +'%I:%M')"
  # CLOCK="$ICON_CLOCK $TIME"

	LEFT="$WORKSPACES"
	CENTER=""
	RIGHT="$BATTERY $VOL $NETWORK $DATE $TIME"

	echo "%{l}$LEFT %{c}$CENTER %{r}$RIGHT "
	sleep 0.2
done
