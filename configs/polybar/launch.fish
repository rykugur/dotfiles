#!/usr/bin/env fish

# kill any existing bars
polybar-msg cmd quit

# echo a separator
echo --- | tee -a /tmp/polybar_primary.log /tmp/polybar_secondary.log

polybar primary -c $DOTFILES_DIR/configs/polybar/config.ini 2>&1 | tee -a /tmp/polybar_primary.log &
disown
polybar secondary -c $DOTFILES_DIR/configs/polybar/config.ini 2>&1 | tee -a /tmp/polybar_secondary.log &
disown
