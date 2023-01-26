set -gx CODE_DIR "$HOME/code"
set -gx GITS "$HOME/gits"
set -gx VISUAL "vim"

switch (uname)
  case Darwin
    set -gx SSH_AUTH_SOCK ~/Library/Group\ Containers/2BUA8C4S2C.com.1password/t/agent.sock
  case Linux
    set -gx SSH_AUTH_SOCK ~/.1password/agent.sock
end

### set additional paths
fish_add_path -a $HOME/bin
# add yarn global if yarn exists
if which -a yarn &> /dev/null
  fish_add_path -a $(yarn global bin)
end

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
