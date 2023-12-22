#!/usr/bin/env fish

set -l lock_time 600
set -l off_time 660

if which -a swayidle &>/dev/null
    echo "swayidle is installed."
    swayidle -w timeout $lock_time 'swaylock -f' timeout $off_time 'hyprctl dispatch dpms off' resume 'hyprctl dispatch dpms on' & disown
else
    echo "swayidle is not installed."
end
