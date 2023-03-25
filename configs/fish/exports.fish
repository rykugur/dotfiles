set -gx CODE_DIR "$HOME/code"
set -gx GITS "$HOME/gits"
set -gx VISUAL vim

### set additional paths
fish_add_path -a $HOME/bin
# add yarn global if yarn exists
if which -a yarn &>/dev/null
    fish_add_path -a $(yarn global bin)
end

# manually override this in ~/.fish_local.fish if needed
set -gx COPYCMD 'xclip -i'
set -gx PASTECMD 'xclip -o'

# don't greet me!
set -gx fish_greeting

### set an editor
set -gx EDITOR vim
set -gx VISUAL vim

set -gx STARSHIP_CONFIG "$DOTFILES_DIR/configs/starship/presets/pure.toml"
# set -gx STARSHIP_CONFIG "$DOTFILES_DIR/configs/starship/presets/tokyo-night.toml"
# set -gx STARSHIP_CONFIG "$DOTFILES_DIR/configs/starship/presets/pastel-powerline.toml"
