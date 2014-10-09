# Path to your oh-my-fish.
set fish_path $HOME/.oh-my-fish

# Theme
set fish_theme rollhax

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-fish/plugins/*)
# Custom plugins may be added to ~/.oh-my-fish/custom/plugins/
# Example format: set fish_plugins autojump bundler
set fish_plugins sublime

# Path to your custom folder (default path is $FISH/custom)
#set fish_custom $HOME/dotfiles/oh-my-fish

# Load oh-my-fish configuration.
. $fish_path/oh-my-fish.fish

#########################
# custom config
#########################

# don't greet me!
set fish_greeting ""

### exports
set -x PATH $PATH ~/bin
set -x GOPATH $HOME/code/go
set -x GOBIN $GOPATH/bin
set -x JAVA_HOME /usr/lib/jvm/java-7-openjdk
#set -x WINEPREFIX "/home/dusty/.wine32"
#set -x WINEARCH "win32"

### "aliases" and quickie functions
alias arches "ssh arches"
alias archesvnc "vncviewer -passwd ~/.vnc/passwd arches:2 &"
alias pingtest "ping google.com"

# pacman aliases
alias pacscc "sudo pacman -Scc"
alias pacsyu "sudo pacman -Syu"
alias pacsyy "sudo pacman -Syy"
alias pacss  "pacman -Ss"
alias pacs   "sudo pacman -S"

# load virtualbox modules (as needed)
alias vboxmp "sudo modprobe -a vboxguest vboxsf vboxvideo"
alias vboxrm "sudo rmmod vboxguest vboxsf vboxvideo"

### source our quickie fish functions
. $HOME/.dotfiles/configs/fish_funcs.fish
