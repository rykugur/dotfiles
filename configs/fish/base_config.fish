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

######################
# exports
######################
set -x EDITOR "vim"
set -x GOPATH "$HOME/code/go"
set -x GOBIN "$GOPATH/bin"
set -x URXVT_CMD "urxvt -pe selection-to-clipboard"

_append_path $HOME/bin PATH
_append_path $GOBIN PATH

######################
# aliases
######################
alias compare_dirs "rsync --dry-run -v -r -c --delete"
alias docs "cd ~/.docs"
alias dush "du -sh"
alias getmyip "dig +short myip.opendns.com @resolver1.opendns.com"
alias grep "grep --color"
# leaving this as an alias instead of abbreviation due to length and formatting business
alias gls "git log --topo-order --stat --pretty=format:\"%C(bold)Commit:%C(reset) %C(green)%H%C(red)%d%n%C(bold)Author:%C(reset) %C(cyan)%an <%ae>%n%C(bold)Date:%C(reset)   %C(blue)%ai (%ar)%C(reset)%n%+B\""
alias notes "cd ~/.notes"
alias pingtest "ping google.com"
alias sclist "systemctl --type=service"
alias vi "vim"
alias ytdl "youtube-dl --no-playlist -x --audio-format mp3 --audio-quality 3"

### optional aliases, depend on a program being on the path
if which -a pydf >> /dev/null
  alias dfh "pydf"
else
  alias dfh "df -h"
end
if which -a ls++ >> /dev/null
  alias ls "/usr/bin/ls++ --potsf"
  alias ll "/usr/bin/ls++ --potsf"
  alias llo "/usr/bin/ls -lh"
  alias lso "/usr/bin/ls"
else
  alias ll "ls -lh"
end

### arch specific aliases
#alias pacdeps "pacman -Qi | sed '/^Depends On/,/^Required By/{ s/^Required By.*$//; H; d }; /^Name/!d; /^Name/{ n;x;}'| sed '/^$/s//==================================================================================/'"
alias pacmir  "sudo reflector --verbose --country 'United States' -l 200 -p http --sort rate --save /etc/pacman.d/mirrorlist"
alias vboxmp "sudo modprobe vboxdrv vboxnetadp vboxnetflt vboxpci"
alias vboxrm "sudo rmmod vvboxdrv vboxnetadp vboxnetflt vboxpci"

# source our abbreviations file
. $HOME/.dotfiles/configs/fish/abbreviations.fish

# don't greet me!
set fish_greeting ""

# Load any local configs
# Do this last, since we might want to append to/override abbreviations, aliases, etc.
if test -e $HOME/.fish_local.fish
  . $HOME/.fish_local.fish
end
