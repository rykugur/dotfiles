# set -gx fish_function_path $fish_conf_dir/functions $fish_function_path
# set -gx fisher_path $DOTFILES_DIR/configs/fish

### set additional paths
fish_add_path $HOME/bin

# add yarn global if yarn exists
if which -a yarn &>/dev/null
    fish_add_path (yarn global bin)
end

# don't greet me!
set -gx fish_greeting

### set an editor
set -gx EDITOR (which nvim)
set -gx VISUAL $EDITOR
set -gx SUDO_EDITOR $EDITOR

# Cursor styles
set -gx fish_vi_force_cursor 1
set -gx fish_cursor_default block
set -gx fish_cursor_insert line blink
set -gx fish_cursor_visual block
set -gx fish_cursor_replace_one underscore

set -gx SSH_AUTH_SOCK ~/.1password/agent.sock

set -gx STARSHIP_CONFIG "$DOTFILES_DIR/configs/starship/starship.toml"
