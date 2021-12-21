set script_path (dirname (realpath (dirname (status -f))))

# set -gx fish_function_path $fish_function_path $HOME/.dotfiles/configs/fish/functions
set -gx fish_function_path $script_path/functions $fish_function_path

# need to add homebrew to the path here so files that are sourced below see installed apps
set -gx PATH /opt/homebrew/bin $PATH

# source our exports file
source $script_path/exports.fish

# source our aliases file(s)
for file in $script_path/alias*
  source $file
end

# source our abbreviations file(s)
for file in $script_path/abbr*
  source $file
end

# Load any local configs
# Do this last, since we might want to append to/override abbreviations, aliases, etc.
if test -e $HOME/.local/fish/config.fish
  source $HOME/.local/fish/config.fish
end

if which -a starship > /dev/null 2>&1
  starship init fish | source
end

set -gx DOTFILES_DIR (get_dots_dir)
