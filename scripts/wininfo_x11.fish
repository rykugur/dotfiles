#!/usr/bin/env fish

notify-send -w -t 60000 "$(xprop | grep -v 'NET_WM_NAME' | grep 'WM_NAME\|WM_CLASS')"
