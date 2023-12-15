if status is-interactive
    # Commands to run in interactive sessions can go here
    echo derpy
end

set -gx DOTFILES_DIR $HOME/gits/dotfiles
set -l fish_conf_dir $DOTFILES_DIR/configs/fish

set script_path (dirname (realpath (dirname (status -f))))

# # set -gx fish_function_path $fish_function_path $HOME/.dotfiles/configs/fish/functions
set -gx fish_function_path $fish_conf_dir/functions $fish_function_path

# need to add homebrew to the path here so files that are sourced below see installed apps
# if which -a brew &>/dev/null
#     set -gx PATH $PATH /opt/homebrew/bin
# end

# source our exports file
source $fish_conf_dir/exports.fish

# source our aliases file(s)
for file in $fish_conf_dir/aliases/*
    source $file
end

# source our abbreviations file(s)
for file in $fish_conf_dir/abbreviations/*
    source $file
end

# Load any local configs
# Do this last, since we might want to append to/override abbreviations, aliases, etc.
for file in $HOME/.local/fish/*.fish
    source $file
end

if test -d $HOME/.local/fish/functions
    set -gx fish_function_path $HOME/.local/fish/functions $fish_function_path
end

if which -a starship >/dev/null 2>&1
    starship init fish | source
end
