if status is-interactive
    # Commands to run in interactive sessions can go here
end

set -gx DOTFILES_DIR $HOME/gits/dotfiles
set -l fish_conf_dir $DOTFILES_DIR/configs/fish

source $fish_conf_dir/exports.fish

for file in $fish_conf_dir/aliases/*
    source $file
end

for file in $fish_conf_dir/abbreviations/*
    source $file
end

# Load any local configs
# Do this last, since we might want to override abbreviations, aliases, etc.
for file in $HOME/.local/fish/*.fish
    source $file
end

if test -d $HOME/.local/fish/functions
    set -gx fish_function_path $HOME/.local/fish/functions $fish_function_path
end

if which -a starship >/dev/null 2>&1
    starship init fish | source
end

fzf_configure_bindings
