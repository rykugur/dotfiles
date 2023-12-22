#!/usr/bin/fish

notify-send -w -t 60000 "$(hyprprop | jq '.class,.title')"
