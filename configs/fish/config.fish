if status is-interactive
    # Commands to run in interactive sessions can go here
end

set -q __fish_personal_dotfiles_sourced; and exit
set -g __fish_personal_dotfiles_sourced 1

set -gx DOTFILES_DIR $HOME/.dotfiles
set -l fish_conf_dir $DOTFILES_DIR/configs/fish

source $fish_conf_dir/exports.fish

for file in $fish_conf_dir/ez/*
    source $file
end

for file in $fish_conf_dir/functions/*
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

zoxide init fish | source
