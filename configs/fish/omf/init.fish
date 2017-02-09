# source fisherman
set -gx fisher_home ~/.dotfiles/deps/fisherman
set -gx fisher_config ~/.config/fisherman
set -gx fisher_file ~/.dotfiles/configs/fish/fisherfile
source $fisher_home/fisher.fish

set -gx fish_function_path $fish_function_path $HOME/.dotfiles/configs/fish/functions

# set additional PATHs
set PATH $PATH $HOME/bin
if not set -q GOPATH
  set -gx GOPATH "$HOME/code/go"
end
if not set -q GOBIN
  set -gx GOBIN "$GOPATH/bin"
end
set PATH $PATH $GOBIN

# set GITS
if not set -q GITS
  set -gx GITS "$HOME/gits"
end

# set DROPBOX_DIR
if not set -q DROPBOX_DIR
  set -gx DROPBOX_DIR "$HOME/dropbox/Dropbox"
end

# set PASTECMD/COPYCMD based on OS
if getos --mac
  set -gx PASTECMD 'pbpaste'
  set -gx COPYCMD  'pbcopy'
else
  set -gx PASTECMD 'xclip -o'
  set -gx COPYCMD  'xclip -i'
end

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
