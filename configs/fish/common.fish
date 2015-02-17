# 'common' fish aliases
# aka those common to home and work

set -x URXVT_CMD "urxvt -pe selection-to-clipboard"

# misc aliases
alias dfh "df -h"
alias docs "cd $DOCS_DIR"
alias dush "du -sh"
alias expenses "gnumeric $DOCS_DIR/personal/finances/monthly_expenses.gnumeric"
alias notes "cd $NOTES_DIR"
alias pingtest "ping google.com"
if test -e /usr/bin/ls++
  alias ls "/usr/bin/ls++ --potsf"
  alias ll "/usr/bin/ls++ --potsf"
  alias llo "/usr/bin/ls -lh"
  alias lso "/usr/bin/ls"
else
  alias ll "ls -lh"
end

# go aliases
alias gocd "cd $GOPATH"

# git aliases
#alias gco "git checkout"
#alias gd  "git diff"
alias gdh "git diff HEAD~1..HEAD"
alias gds "git diff --staged"
#alias gg  "git grep"
alias gls "git log --topo-order --stat --pretty=format:\"%C(bold)Commit:%C(reset) %C(green)%H%C(red)%d%n%C(bold)Author:%C(reset) %C(cyan)%an <%ae>%n%C(bold)Date:%C(reset)   %C(blue)%ai (%ar)%C(reset)%n%+B\""
alias gsl "git stash list | cat"
alias gss "git status --short"

# pacman aliases
#alias spscc "sudo pacman -Scc"
#alias spsyu "sudo pacman -Syu"
#alias spsyy "sudo pacman -Syy"
#alias pss   "pacman -Ss"
#alias pqs   "pacman -Qs"
#alias sps   "sudo pacman -S"
#alias spr   "sudo pacman -R"
#alias pacdeps "pacman -Qi | sed '/^Depends On/,/^Required By/{ s/^Required By.*$//; H; d }; /^Name/!d; /^Name/{ n;x;}'| sed '/^$/s//==================================================================================/'"
alias pacmir  "sudo reflector --verbose --country 'United States' -l 200 -p http --sort rate --save /etc/pacman.d/mirrorlist"

# load virtualbox modules (as needed)
alias vboxmp "sudo modprobe vboxdrv vboxnetadp vboxnetflt vboxpci"
alias vboxrm "sudo rmmod vvboxdrv vboxnetadp vboxnetflt vboxpci"
