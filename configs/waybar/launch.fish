#!/usr/bin/env fish

killall waybar
sleep 0.5

waybar -c $DOTFILES_DIR/configs/waybar/config.json
