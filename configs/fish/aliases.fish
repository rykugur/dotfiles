### misc aliases
alias cmd.copy         "eval $COPYCMD"
alias cmd.paste        "eval $PASTECMD"
alias compare_dirs     "rsync --dry-run -v -r -c --delete"
alias dush             "du -sh"
alias getmyip          "dig +short myip.opendns.com @resolver1.opendns.com"
alias grep             "grep --color"
alias jsonify          "to.json -p"
alias pingtest         "ping google.com"
alias resrc            "source $HOME/.config/fish/config.fish"
alias trim.newlines    "tr -d \"\n\r\""
# working: awk '{printf "%s\\n", $0}'
alias replace.newlines "awk '{printf \"%s\\n\", \$0}'"
alias trim.spaces      "sed -E 's/[[:space:]]+/ /g'"
alias vi               "vim"
alias vimnotes         "vim -c VimwikiIndex"
alias ytdl             "youtube-dl --no-playlist -x --audio-format mp3 --audio-quality 3"
###### fast travel
alias configs   "gits -c"
alias docs      "cd $HOME/docs"
alias dots      "gits -d"
alias dots.fish "gits -f"
alias notes     "cd $HOME/.notes"
###### onepassword-specific
alias op.auth   'set -gx OP_SESSION_rollhax (op signin $OP_LOGIN_HOST.1password.com $OP_LOGIN_EMAIL $OP_LOGIN_KEY --output=raw)'
alias op.reauth 'set -gx OP_SESSION_rollhax (op signin $OP_LOGIN_HOST --output=raw)'
alias op.item   'op get item'
alias jq.pass   'jq \'.details.fields[] | select(.designation=="password").value\' | tr -d "\""'
###### git-specific
# alias gbn            "git status | head -n1 | awk '{print \$3}'"
alias gbn            "git branch | cut -d' ' -f2"
alias glg            "git log --graph --pretty=format:'%Cgreen[%h]%Creset %C(white)%d%Creset %Cblue%ad by %an%Creset: %s' --date=relative"
alias gll            "git log --pretty=format:'%Cgreen[%H]%Creset %C(white)%d%Creset %Cblue%ad by %an%Creset: %s' --date=relative"
alias gls            "git log --topo-order --stat --pretty=format:\"%C(bold)Commit:%C(reset) %C(green)%H%C(red)%d%n%C(bold)Author:%C(reset) %C(cyan)%an <%ae>%n%C(bold)Date:%C(reset)   %C(blue)%ai (%ar)%C(reset)%n%+B\""
alias git.back       "git reset HEAD~1"
alias git.clean      "git branch --merged (git.branch) | grep -v (git.branch) | xargs git branch -d"
alias git.lastcommit "git log | head -n1 | awk '{print \$2}' | trim.newlines"
alias git.head       "gll | head -n1"
alias jedi           "git push --force"
###### arch-specific
#alias pacdeps "pacman -Qi | sed '/^Depends On/,/^Required By/{ s/^Required By.*$//; H; d }; /^Name/!d; /^Name/{ n;x;}'| sed '/^$/s//==================================================================================/'"
alias pac.mirror     "sudo reflector --verbose --country 'United States' -l 200 -p http --sort rate --save /etc/pacman.d/mirrorlist"
alias vbox.mod.load  "sudo modprobe vboxdrv vboxnetadp vboxnetflt vboxpci"
alias vbox.mod.rm    "sudo rmmod vvboxdrv vboxnetadp vboxnetflt vboxpci"
###### systemd-specific
alias sclist "systemctl --type=service"
###### ssh
alias bale     "ssh balescream"
alias ssh.bale "ssh balescream"
alias ssh.home "ssh rollhax.io"
###### lazy-mode awk-aliases until I'm not lazy and write a proper script
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
if which -a pydf > /dev/null
  alias dfh "pydf"
else
  alias dfh "df -h"
end
if which -a ls++ > /dev/null
  alias ls "ls++ --potsf"
  alias ll "ls++ --potsf"
  alias llo "/usr/bin/ls -lh"
  alias lso "/usr/bin/ls"
else
  alias ll "ls -lh"
end
