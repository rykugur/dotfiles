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

######################
# exports
######################
set -x EDITOR "vim"
set -x GOPATH "/home/djerome/personal/code/go"
set -x GOBIN "$GOPATH/bin"
set -x JAVA_HOME "/usr/lib/jvm/java-7-openjdk"

# don't greet me!
set fish_greeting ""
