set -gx CODE_DIR "$HOME/code"
set -gx EDITOR "vim"
set -gx GITS "$HOME/gits"
set -gx VISUAL "vim"
set -gx GOPATH "$CODE_DIR/go"
set -gx GOBIN "$GOPATH/bin"

# set additional paths
set PATH $PATH $HOME/bin

# golang!
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

# set paste/copy aliases
if getos --mac
  set -gx PASTECMD 'pbpaste'
  set -gx COPYCMD  'pbcopy'
else
  set -gx PASTECMD 'xclip -o'
  set -gx COPYCMD  'xclip -i'
end

# set DROPBOX_DIR
if not set -q DROPBOX_DIR
  set -gx DROPBOX_DIR "$HOME/dropbox/Dropbox"
end

# don't greet me!
set fish_greeting ""
