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
set -x URXVT_CMD "urxvt -pe selection-to-clipboard"
set -x WINEPREFIX "/home/dusty/.wine32"
set -x WINEARCH "win32"

set PATH $PATH ~/bin

_append_path $GOBIN PATH

######################
# aliases
######################
alias dfh "df -h"
alias docs "cd $DOCS_DIR"
alias dush "du -sh"
alias expenses "open $EXPENSES_FILE"
# leaving this as an alias instead of abbreviation due to length and formatting business
alias gls "git log --topo-order --stat --pretty=format:\"%C(bold)Commit:%C(reset) %C(green)%H%C(red)%d%n%C(bold)Author:%C(reset) %C(cyan)%an <%ae>%n%C(bold)Date:%C(reset)   %C(blue)%ai (%ar)%C(reset)%n%+B\""
alias home_cp_start "ssh $HOME_SERVER_ADDRESS 'crashplan/bin/crashplan start'"
alias home_cp_stop "ssh $HOME_SERVER_ADDRESS 'crashplan/bin/crashplan stop'"
alias notes "cd $PERSONAL_NOTES_DIR"
alias pingtest "ping google.com"
alias steamcd "cd $STEAM_DIR"
if test -e /usr/bin/ls++
  alias ls "/usr/bin/ls++ --potsf"
  alias ll "/usr/bin/ls++ --potsf"
  alias llo "/usr/bin/ls -lh"
  alias lso "/usr/bin/ls"
else
  alias ll "ls -lh"
end

# arch specific aliases
#alias pacdeps "pacman -Qi | sed '/^Depends On/,/^Required By/{ s/^Required By.*$//; H; d }; /^Name/!d; /^Name/{ n;x;}'| sed '/^$/s//==================================================================================/'"
alias pacmir  "sudo reflector --verbose --country 'United States' -l 200 -p http --sort rate --save /etc/pacman.d/mirrorlist"
alias vboxmp "sudo modprobe vboxdrv vboxnetadp vboxnetflt vboxpci"
alias vboxrm "sudo rmmod vvboxdrv vboxnetadp vboxnetflt vboxpci"

######################
# abbreviations
######################
# fish abbreviations allow you to define... well... abbreviations... so that when you type e.g. "gc"
# and press space, it is automatically expanded to "git commit"
set -x fish_user_abbreviations ..='cd ..' \
                               ...='cd ../..' \
                               ....='cd ../../..' \
                               fn='find . -name' \
                               fin='find . -iname' \
                               ga='git add' \
                               gc='git commit' \
                               gca='git commit --amend' \
                               gcm='git commit -m' \
                               gco='git checkout' \
                               gd='git diff' \
                               gds='git diff --staged' \
                               gf='git fetch' \
                               gfp='git fetch -p' \
                               gg='git grep' \
                               gl='git log' \
                               gp='git pull' \
                               gs='git stash' \
                               gsl='git stash list | cat' \
                               gss='git status --short' \
                               gr='grep --color=auto' \
                               grE='grep --color=auto -niRE' \
                               pagi='ps aux | grep -v grep | grep -i' \
                               supac='sudo pacman' \
                               supacr='sudo pacman -R' \
                               supacs='sudo pacman -S' \
                               pac='pacman' \
                               pacr='pacman -R' \
                               pacs='pacman -S' \
                               pacss='pacman -Ss' \
                               sc='systemctl' \
                               ssc='sudo systemctl' \
                               sscr='sudo systemctl restart' \
                               sv='sudo vim'

# don't greet me!
set fish_greeting ""
