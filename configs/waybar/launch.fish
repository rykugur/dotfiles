#!/usr/bin/env fish

kill (ps aux | grep -v grep | grep -i waybar | awk2)
sleep 0.5

waybar -c $HOME/.config/waybar/config.json & disown
