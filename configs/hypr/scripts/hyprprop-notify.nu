#!/usr/bin/env nu

let props = (hyprprop | from json | select class title initialClass initialTitle)
$props | table

notify-send ($props | to json)
# print $"props=($props)"
# let clients = (hyprctl clients -j | from json)
# let eve_clients = ($clients | where {|c| $c.title | str starts-with "EVE - "} | sort-by pid)

