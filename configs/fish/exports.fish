set -gx CODE_DIR "$HOME/code"
set -gx GITS "$HOME/gits"
set -gx VISUAL vim

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
# set -gx STARSHIP_CONFIG "$DOTFILES_DIR/configs/starship/presets/bracketed-segments.toml"
# set -gx STARSHIP_CONFIG "$DOTFILES_DIR/configs/starship/presets/plain-text-symbols.toml"
# set -gx STARSHIP_CONFIG "$DOTFILES_DIR/configs/starship/presets/nerd-font-symbols.toml"
# set -gx STARSHIP_CONFIG "$DOTFILES_DIR/configs/starship/presets/pure.toml"
# set -gx STARSHIP_CONFIG "$DOTFILES_DIR/configs/starship/presets/tokyo-night.toml"
# set -gx STARSHIP_CONFIG "$DOTFILES_DIR/configs/starship/presets/pastel-powerline.toml"
