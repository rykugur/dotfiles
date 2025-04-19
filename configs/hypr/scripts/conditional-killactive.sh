#!/usr/bin/env bash

# because I'm tired of accidentally killing EVE online when I
# mis-press Alt+C for cargo.

if hyprctl activewindow | grep -q "class.*steam_app_8500"; then
    # If the active window is my_app_using_F3, do nothing
    exit 0
else
    # Otherwise, close the active window
    hyprctl dispatch killactive
fi
