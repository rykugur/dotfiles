set -gx CODE_DIR "$HOME/code"
set -gx EDITOR "vim"
set -gx GITS "$HOME/gits"
set -gx VISUAL "vim"

### set additional paths
set PATH $PATH $HOME/bin
# required for ls++ if installed from arch repo
set PATH $PATH /usr/bin/vendor_perl
set PATH $PATH /usr/local/bin

# manually override this in ~/.fish_local.fish if needed
set -gx COPYCMD  'xclip -i'
set -gx PASTECMD 'xclip -o'

# don't greet me!
set -gx fish_greeting
