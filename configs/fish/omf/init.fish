# source fisherman
#set -gx fisher_home ~/.dotfiles/deps/fisherman
#set -gx fisher_config ~/.config/fisherman
#set -gx fisher_file ~/.dotfiles/configs/fish/fisherfile
#source $fisher_home/fisher.fish

# set -gx fish_function_path $fish_function_path $HOME/.dotfiles/configs/fish/functions
set -gx fish_function_path $HOME/.dotfiles/configs/fish/functions $fish_function_path

# source our exports file
source $HOME/.dotfiles/configs/fish/exports.fish

# source our aliases file
for file in $HOME/.dotfiles/configs/fish/alias*
  source $file
end

# source our abbreviations files
for file in $HOME/.dotfiles/configs/fish/abbr*
  source $file
end

# Load any local configs
# Do this last, since we might want to append to/override abbreviations, aliases, etc.
if test -e $HOME/.fish_local.fish
  source $HOME/.fish_local.fish
end

if which -a starship > /dev/null 2>&1
  starship init fish | source
end
