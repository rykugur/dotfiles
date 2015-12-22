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

# Other potential fish function directories
if [ -e $HOME/.dotfiles/configs/fish/functions ]
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
alias docs "cd $DOCS_DIR"
alias dush "du -sh"
alias getmyip "dig +short myip.opendns.com @resolver1.opendns.com"
# leaving this as an alias instead of abbreviation due to length and formatting business
alias grep "grep --color"
alias gls "git log --topo-order --stat --pretty=format:\"%C(bold)Commit:%C(reset) %C(green)%H%C(red)%d%n%C(bold)Author:%C(reset) %C(cyan)%an <%ae>%n%C(bold)Date:%C(reset)   %C(blue)%ai (%ar)%C(reset)%n%+B\""
alias home_cp_start "ssh $HOME_SERVER_ADDRESS 'crashplan/bin/crashplan start'"
alias home_cp_stop "ssh $HOME_SERVER_ADDRESS 'crashplan/bin/crashplan stop'"
alias hosts "sudo vim /etc/hosts"
alias notes "cd $PERSONAL_NOTES_DIR"
alias restart_netwk "sudo systemctl restart dhcpcd@$DEFAULT_NETWORK_INTERFACE.service"
alias pingtest "ping google.com"
alias sclist "systemctl --type=service"
alias steamcd "cd $STEAM_DIR"
if which -a pydf >> /dev/null
  alias dfh "pydf"
else
  alias dfh "df -h"
end
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
                               cwd='pwd | xclip -i' \
                               fn='find . -name' \
                               fin='find . -iname' \
                               ga='git add' \
                               gbc='git branch --contains' \
                               gc='git commit' \
                               gca='git commit --amend' \
                               gcm='git commit -m' \
                               gco='git checkout' \
                               gco.='git checkout .' \
                               gcob='git checkout -b' \
                               gcp='git cherry-pick' \
                               gcu='rm -rf (git status --short | cut -d" " -f2)' \
                               gd='git diff' \
                               gds='git diff --staged' \
                               gf='git fetch' \
                               gfp='git fetch -p' \
                               gg='git grep --color=auto -n' \
                               ggi='git grep --color=auto -ni' \
                               gl='git log' \
                               gpl='git pull' \
                               gps='git push' \
                               gpls='git pull; and git push' \
                               gr='git reset' \
                               grh='git reset HEAD' \
                               grhh='git reset --hard HEAD' \
                               gs='git stash' \
                               gsl='git stash list | cat' \
                               gsp='git stash pop' \
                               gss='git status --short' \
                               grn='grep -n' \
                               grin='grep -ni' \
                               grine='grep -niRE' \
                               pagi='ps aux | grep -v grep | grep -i' \
                               pac='pacman' \
                               pacr='pacman -R' \
                               pacrcs='pacman -Rcs' \
                               pacs='pacman -S' \
                               pacscc='pacman -Scc' \
                               pacsyu='pacman -Syu' \
                               pacsyy='pacman -Syy' \
                               pacsyyu='pacman -Syyu' \
                               supac='sudo pacman' \
                               supacr='sudo pacman -R' \
                               supacrcs='sudo pacman -Rcs' \
                               supacs='sudo pacman -S' \
                               supacscc='sudo pacman -Scc' \
                               supacsyu='sudo pacman -Syu' \
                               supacsyy='sudo pacman -Syy' \
                               supacsyyu='sudo pacman -Syyu' \
                               supacu='sudo pacman -U' \
                               sc='systemctl' \
                               scr='systemctl restart' \
                               scs='systemctl start' \
                               scst='systemctl status' \
                               ssc='sudo systemctl' \
                               sscr='sudo systemctl restart' \
                               sscs='sudo systemctl start' \
                               sscst='sudo systemctl status' \
                               sv='sudo vim' \
                               svec='sudo vim /etc/hosts' \
                               taill='tail -Fn 999'

# don't greet me!
set fish_greeting ""

# Load any local configs
# Do this last, since we might want to append to abbreviations
if test -e $HOME/.fish_local.fish
  . $HOME/.fish_local.fish
end
