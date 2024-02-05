#!/usr/bin/env fish

kill (pgrep waybar) &>/dev/null
sleep 0.5

waybar -c $HOME/.config/waybar/config.json & disown
