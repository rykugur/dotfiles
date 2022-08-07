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
if which -a gedit &> /dev/null
  set -gx EDITOR "gedit"
  set -gx VISUAL "gedit"
else if which -a code &> /dev/null
  set -gx EDITOR "code"
  set -gx VISUAL "code"
else if which -a vim &> /dev/null
  set -gx EDITOR "vim"
  set -gx VISUAL "vim"
end

set -gx STARSHIP_CONFIG "$DOTFILES_DIR/configs/starship/pure-preset.toml"
# set -gx STARSHIP_CONFIG "$DOTFILES_DIR/configs/starship/pastel-powerline.toml"