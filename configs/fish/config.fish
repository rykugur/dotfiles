# this file exists because I use the same setup at work, but don't want work-specific config files
# on my public github account. It's sourced by local config.fish files, along with other fish
# config files.

# source oh-my-fish
set -gx OMF_PATH "$HOME/.local/share/omf"
set -gx OMF_CONFIG "$HOME/.dotfiles/configs/fish/omf"
source $OMF_PATH/init.fish

# source fisherman
set fisher_home ~/.dotfiles/deps/fisherman
set fisher_config ~/.config/fisherman
set fisher_file ~/.dotfiles/configs/fish/fisherfile
source $fisher_home/fisher.fish

set fish_function_path $fish_function_path $HOME/.dotfiles/configs/fish/functions

set PATH $PATH $HOME/bin
set PATH $PATH $GOBIN

# source our exports file
source $HOME/.dotfiles/configs/fish/exports.fish

# source our aliases file
source $HOME/.dotfiles/configs/fish/aliases.fish

# source our abbreviations file
source $HOME/.dotfiles/configs/fish/abbreviations.fish

# don't greet me!
set fish_greeting ""

# Load any local configs
# Do this last, since we might want to append to/override abbreviations, aliases, etc.
if test -e $HOME/.fish_local.fish
  source $HOME/.fish_local.fish
end
