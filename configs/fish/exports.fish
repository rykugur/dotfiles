set -gx CODE_DIR "$HOME/code"
set -gx EDITOR "vim"
set -gx GITS "$HOME/gits"
set -gx VISUAL "vim"

### set additional paths
set PATH $PATH $HOME/bin
# required for ls++ if installed from arch repo
set PATH $PATH /usr/bin/vendor_perl

# set GITS
if not set -q GITS
  set -gx GITS "$HOME/gits"
end

# manually override this in ~/.fish_local.fish if needed
set -gx COPYCMD  'xclip -i'
set -gx PASTECMD 'xclip -o'

# set DROPBOX_DIR
if not set -q DROPBOX_DIR
  set -gx DROPBOX_DIR "$HOME/dropbox/Dropbox"
end

# don't greet me!
set fish_greeting ""
