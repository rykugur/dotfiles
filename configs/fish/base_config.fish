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

# Load any local configs
if [ -e $HOME/.fish_local.fish ]
  . $HOME/.fish_local.fish
end

# Other potential fish function directories
if [ -e $HOME/.dotfiles/fish/functions ]
  _append_path $HOME/.dotfiles/fish/functions fish_function_path
end


######################
# exports
######################
set -x EDITOR "vim"
set -x GOPATH "$HOME/personal/code/go"
set -x GOBIN "$GOPATH/bin"
set -x JAVA_HOME "/usr/lib/jvm/java-7-openjdk"

# fish abbreviations allow you to define... well... abbreviations... so that when you type e.g. "gc"
# and press space, it is automatically expanded to "git commit"
set -x fish_user_abbreviations 'ga=git add' 'gc=git commit' 'gco=git checkout' 'gd=git diff' 'gds=git diff --staged' 'gf=git fetch' 'gg=git grep' geg='git grep -E' 'gp=git pull' 'supac=sudo pacman' 'supacs=sudo pacman -S' 'pac=pacman' pacss='pacman -Ss' 'sc=systemctl' 'ssc=sudo systemctl' 'sscr=sudo systemctl restart'

# don't greet me!
set fish_greeting ""
