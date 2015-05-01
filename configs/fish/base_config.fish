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
set -x JAVA_HOME "/usr/lib/jvm/jdk1.7.0_71"

_append_path $GOBIN PATH

# fish abbreviations allow you to define... well... abbreviations... so that when you type e.g. "gc"
# and press space, it is automatically expanded to "git commit"
set -x fish_user_abbreviations ..='cd ..' \
                               ...='cd ../..' \
                               ....='cd ../../..' \
                               ga='git add' \
                               gc='git commit' \
                               gca='git commit --amend' \
                               gco='git checkout' \
                               gd='git diff' \
                               gds='git diff --staged' \
                               gf='git fetch' \
                               gfp='git fetch -p' \
                               gg='git grep' \
                               gp='git pull' \
                               gs='git stash' \
                               gsl='git stash list | cat' \
                               gss='git status --short' \
                               gr='grep --color=auto' \
                               grE='grep --color=auto -niRE' \
                               pagi='ps aux | grep -v grep | grep -i' \
                               supac='sudo pacman' \
                               supacs='sudo pacman -S' \
                               pac='pacman' \
                               pacss='pacman -Ss' \
                               sc='systemctl' \
                               ssc='sudo systemctl' \
                               sscr='sudo systemctl restart' \
                               sv='sudo vim'

# don't greet me!
set fish_greeting ""
