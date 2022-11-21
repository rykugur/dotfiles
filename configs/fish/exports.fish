set -gx CODE_DIR "$HOME/code"
set -gx GITS "$HOME/gits"
set -gx VISUAL "vim"

### set additional paths
set PATH $PATH $HOME/bin

# manually override this in ~/.fish_local.fish if needed
set -gx COPYCMD  'xclip -i'
set -gx PASTECMD 'xclip -o'

# don't greet me!
set -gx fish_greeting

### set an editor
set -gx EDITOR "vim"
set -gx VISUAL "vim"

set -gx STARSHIP_CONFIG "$DOTFILES_DIR/configs/starship/pure-preset.toml"
# set -gx STARSHIP_CONFIG "$DOTFILES_DIR/configs/starship/pastel-powerline.toml"
