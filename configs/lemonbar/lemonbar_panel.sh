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

while :; do
  DESKTOP_1="$ICON_TERM misc"
  DESKTOP_2="$ICON_FIREFOX www"
  DESKTOP_3="$ICON_GAME game"
  DESKTOP_4="$ICON_CODE code"

  CURR_DESKTOP_NUM=$(get_current_desktop_num)
  if [ $CURR_DESKTOP_NUM = "0" ]; then
    # DESKTOP_1="%{+u B${COLOR_URGENT_BG} U${COLOR_BACKGROUND}}${COLOR_URGENT_BG}}$DESKTOP_1"
    # DESKTOP_1="%{+u B${COLOR_URGENT_BG}}${COLOR_URGENT_BG}}$DESKTOP_1"
    DESKTOP_1="%{+u B${COLOR_ACTIVE_WORKSPACE} U${COLOR_ACTIVE_WORKSPACE_INDICATOR}} $DESKTOP_1 %{-u B${COLOR_BACKGROUND}}"
  elif [ $CURR_DESKTOP_NUM = "1" ]; then
    DESKTOP_2="%{+u B${COLOR_ACTIVE_WORKSPACE} U${COLOR_ACTIVE_WORKSPACE_INDICATOR}} $DESKTOP_2 %{-u B${COLOR_BACKGROUND}}"
  elif [ $CURR_DESKTOP_NUM = "2" ]; then
    DESKTOP_3="%{+u B${COLOR_ACTIVE_WORKSPACE} U${COLOR_ACTIVE_WORKSPACE_INDICATOR}} $DESKTOP_3 %{-u B${COLOR_BACKGROUND}}"
  elif [ $CURR_DESKTOP_NUM = "3" ]; then
    DESKTOP_4="%{+u B${COLOR_ACTIVE_WORKSPACE} U${COLOR_ACTIVE_WORKSPACE_INDICATOR}} $DESKTOP_4 %{-u B${COLOR_BACKGROUND}}"
  fi

  WORKSPACES="$DESKTOP_1 $DESKTOP_2 $DESKTOP_3 $DESKTOP_4"
  
  BATTERY=""
  if [ "$(ls -A /sys/class/power_supply/)" ]; then
    BATTERY_STATUS=$(cat /sys/class/power_supply/BAT1/status)
    if [ $BATTERY_STATUS = "Discharging" ]; then
      CURR_BATTERY_PERCENT=$(acpi | awk '{print $4}' | sed -e 's/,//g' | sed -e 's/%//g')

      if [ $CURR_BATTERY_PERCENT -lt 10 ]; then
        ICON_BATTERY="$%{+u U${COLOR_WARN}} ICON_BATTERY_0_ALT"
      elif [ $CURR_BATTERY_PERCENT -lt 25 ]; then 
        ICON_BATTERY="$%{+u U${COLOR_WARN}} ICON_BATTERY_25"
      elif [ $CURR_BATTERY_PERCENT -lt 50 ]; then
        ICON_BATTERY="$ICON_BATTERY_50"
      elif [ $CURR_BATTERY_PERCENT -lt 75 ]; then
        ICON_BATTERY="$ICON_BATTERY_75"
      else
        ICON_BATTERY="$ICON_BATTERY_100"
      fi

      BATTERY="$ICON_BATTERY $CURR_BATTERY_PERCENT%"
    fi
  fi

  CURR_VOL_PERCENT=$(pactl list sinks | egrep "Volume.*\%" | head -n1 | awk '{print $5}')
  VOL="$ICON_VOLUME $CURR_VOL_PERCENT"

	NETWORK_ICON="$ICON_NETWORK_ETH" # default to ethernet icon
  IP_ADDR=$(ip addr show $DEFAULT_NETWORK_INTERFACE | awk '/inet / {print $2}' | sed -e 's/\/[0-9]*//g')
  NETWORK="$NETWORK_ICON $IP_ADDR"

  DATE="$ICON_CALENDAR $(date +'%m.%d')"
  TIME="$ICON_CLOCK $(date +'%I:%M')"

	LEFT="$WORKSPACES"
	CENTER=""
	RIGHT="$BATTERY $VOL $NETWORK %{B${COLOR_ACTIVE_WORKSPACE}} $DATE $TIME %{B${COLOR_BACKGROUND}}"

	echo "%{l} $LEFT %{c}$CENTER %{r}$RIGHT"

  # TODO: are we sleeping long enough so as to not cause too much cpu utilizabtion for a
  # panel script?
	# sleep 0.2
	sleep 0.1
done
