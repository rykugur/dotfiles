# source our base_config.fish file
. $HOME/.dotfiles/configs/fish/base_config.fish

# source our common.fish file
. $HOME/.dotfiles/configs/fish/common.fish

# source our quickie fish functions
. $HOME/.dotfiles/configs/fish/fish_funcs.fish

### exports
set PATH $PATH ~/bin
set -x WINEPREFIX "/home/dusty/.wine32"
set -x WINEARCH "win32"

### "aliases" and quickie functions
alias arches "ssh arches"
alias archesvnc "vncviewer -passwd ~/.vnc/passwd arches:2 &"

alias ta "transmission-remote $ARCHES:$ARCHES_TRANSMISSION_PORT -a"
