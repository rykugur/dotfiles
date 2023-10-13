set script_path (dirname (realpath (dirname (status -f))))

# TODO: figure out why items on the path are showing up multiple times even before this file is sourced
# echo $PATH | string split ' ' | sort | uniq -c >>~/path_fun
echo 'sourcing init.fish' >>~/fish_trace

# set -gx fish_function_path $fish_function_path $HOME/.dotfiles/configs/fish/functions
set -gx fish_function_path $script_path/functions $fish_function_path
set -gx DOTFILES_DIR (get_dots_dir)

# need to add homebrew to the path here so files that are sourced below see installed apps
if which -a brew &>/dev/null
    set -gx PATH $PATH /opt/homebrew/bin
end

# source our exports file
source $script_path/exports.fish

# source our aliases file(s)
for file in $script_path/aliases/*
    source $file
end

# source our abbreviations file(s)
for file in $script_path/abbreviations/*
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
