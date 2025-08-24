#!/usr/bin/env nu

let props = (hyprprop | from json | select class title initialClass initialTitle)
$props | to json | wl-copy
