# this file exists because I use the same setup at work, but don't want work-specific config files
# on my public github account. It's sourced by local config.fish files, along with other fish
# config files.

# Path to your oh-my-fish.
set fish_path $HOME/.oh-my-fish

# Theme
set fish_theme rollhax

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-fish/plugins/*)
# Custom plugins may be added to ~/.oh-my-fish/custom/plugins/
# Example format: set fish_plugins autojump bundler
set fish_plugins sublime

# Load oh-my-fish configuration.
. $fish_path/oh-my-fish.fish

# source fisherman
set fisher_home ~/.dotfiles/deps/fisherman
set fisher_config ~/.config/fisherman
set fisher_file ~/.dotfiles/configs/fish/fisherfile
source $fisher_home/config.fish

# Other potential fish function directories
if test -e $HOME/.dotfiles/configs/fish/functions
  _append_path $HOME/.dotfiles/configs/fish/functions fish_function_path
end

_append_path $HOME/bin PATH
_append_path $GOBIN PATH

# source our exports file
. $HOME/.dotfiles/configs/fish/exports.fish

# source our aliases file
. $HOME/.dotfiles/configs/fish/aliases.fish

# source our abbreviations file
. $HOME/.dotfiles/configs/fish/abbreviations.fish

# don't greet me!
set fish_greeting ""

# Load any local configs
# Do this last, since we might want to append to/override abbreviations, aliases, etc.
if test -e $HOME/.fish_local.fish
  . $HOME/.fish_local.fish
end
