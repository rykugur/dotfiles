#!/usr/bin/env nu

# because I'm tired of accidentally killing EVE online when I
# mis-press Alt+C for cargo.

def is_in_list [value, list: list] {
  $value in $list
}

let protected_app_classes = ["steam_app_8500"]
let active_class = (hyprctl activewindow | parse -r 'class: (?<class>.+)' | get class | first)
let is_present = (is_in_list $active_class $protected_app_classes)

if $is_present {
    # If the active window is my_app_using_F3, do nothing
    exit 0
} else {
    # Otherwise, close the active window
    hyprctl dispatch killactive
}
