### misc aliases
alias compare_dirs "rsync --dry-run -v -r -c --delete"
alias docs "cd ~/.docs"
alias dush "du -sh"
alias getmyip "dig +short myip.opendns.com @resolver1.opendns.com"
alias grep "grep --color"
# leaving this as an alias instead of abbreviation due to length and formatting business
alias glg "git log --graph --pretty=format:'%Cgreen[%h]%Creset %C(white)%d%Creset %Cblue%ad by %an%Creset: %s' --date=relative"
alias gll "git log --pretty=format:'%Cgreen[%H]%Creset %C(white)%d%Creset %Cblue%ad by %an%Creset: %s' --date=relative"
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

