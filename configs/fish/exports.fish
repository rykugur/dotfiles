### set additional paths
set -gx PATH $PATH $HOME/bin

# add yarn global if yarn exists
if which -a yarn &>/dev/null
    set -gx PATH $PATH (yarn global bin)
end

# don't greet me!
set -gx fish_greeting

### set an editor
set -gx EDITOR nvim
set -gx VISUAL nvim

set -gx STARSHIP_CONFIG "$DOTFILES_DIR/configs/starship/starship.toml"
