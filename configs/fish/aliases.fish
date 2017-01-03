### misc aliases
alias compare_dirs "rsync --dry-run -v -r -c --delete"
alias docs         "cd $HOME/docs"
alias dots         "gits -d"
alias dots.fish    "gits -f"
alias dush         "du -sh"
alias getmyip      "dig +short myip.opendns.com @resolver1.opendns.com"
alias grep         "grep --color"
alias gbn          "git status | head -n1 | awk '{print \$3}'"
alias glg          "git log --graph --pretty=format:'%Cgreen[%h]%Creset %C(white)%d%Creset %Cblue%ad by %an%Creset: %s' --date=relative"
alias gll          "git log --pretty=format:'%Cgreen[%H]%Creset %C(white)%d%Creset %Cblue%ad by %an%Creset: %s' --date=relative"
alias gls          "git log --topo-order --stat --pretty=format:\"%C(bold)Commit:%C(reset) %C(green)%H%C(red)%d%n%C(bold)Author:%C(reset) %C(cyan)%an <%ae>%n%C(bold)Date:%C(reset)   %C(blue)%ai (%ar)%C(reset)%n%+B\""
alias git_clean    "git branch --merged development | grep -v development | xargs git branch -d"
alias jedi         "git push --force"
alias jsonify      "xclip -o | python -m json.tool"
alias notes        "cd $HOME/.notes"
alias pingtest     "ping google.com"
alias resrc        "source $HOME/.config/fish/config.fish"
alias sclist       "systemctl --type=service"
alias vi           "vim"
alias vimnotes     "vim -c VimwikiIndex"
alias ytdl         "youtube-dl --no-playlist -x --audio-format mp3 --audio-quality 3"

### lazy-mode awk-aliases until I'm not lazy and write a proper script
alias awk1 "awk '{print \$1}'"
alias awk2 "awk '{print \$2}'"
alias awk3 "awk '{print \$3}'"
alias awk4 "awk '{print \$4}'"
alias awk5 "awk '{print \$5}'"
alias awk6 "awk '{print \$6}'"
alias awk7 "awk '{print \$7}'"
alias awk8 "awk '{print \$8}'"
alias awk9 "awk '{print \$9}'"

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

### alias xclip->pbcopy if on OSX
if test (uname) = "Darwin"
  alias xclip "pbcopy"
end

### arch specific aliases
#alias pacdeps "pacman -Qi | sed '/^Depends On/,/^Required By/{ s/^Required By.*$//; H; d }; /^Name/!d; /^Name/{ n;x;}'| sed '/^$/s//==================================================================================/'"
alias pac.mirror "sudo reflector --verbose --country 'United States' -l 200 -p http --sort rate --save /etc/pacman.d/mirrorlist"
alias vboxmp     "sudo modprobe vboxdrv vboxnetadp vboxnetflt vboxpci"
alias vboxrm     "sudo rmmod vvboxdrv vboxnetadp vboxnetflt vboxpci"

