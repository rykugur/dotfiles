### misc aliases
alias cmd.copy "eval $COPYCMD"
alias cmd.paste "eval $PASTECMD"
alias dupes "find . ! -empty -type f -exec md5sum {} + | sort | uniq -w32 -dD"
alias dush "du -sh"
alias getmyip "dig +short myip.opendns.com @resolver1.opendns.com"
alias grep "grep --color"
alias pingtest "ping google.com"
alias replace.newlines "awk '{printf \"%s\\n\", \$0}'"
alias trim.spaces "sed -E 's/[[:space:]]+/ /g'"
alias vi vim
alias ytdl "youtube-dl --no-playlist -x --audio-format mp3 --audio-quality 3"

###### fast travel
alias .local "cd ~/.local/fish"
if test -e $HOME/.local/fish/config.fish
    alias fish.local "$EDITOR $HOME/.local/fish/config.fish"
end

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
if which -a duf &>/dev/null
    alias dfh duf
else if which -a pydf &>/dev/null
    alias dfh pydf
else
    alias dfh "df -h"
end

if which -a exa &>/dev/null
    alias ls exa
    alias ll "exa -g --long --header --git"
else if which -a ls++ &>/dev/null
    alias ls "ls++ --potsf"
    alias ll "ls++ --potsf"
    alias llo "/usr/bin/ls -lh"
    alias lso /usr/bin/ls
else
    alias ll "ls -lh"
end

if which -a btop &>/dev/null
    alias top btop
else if which -a bashtop &>/dev/null
    alias top bashtop
else if which -a bpytop &>/dev/null
    alias top bpytop
end

if which -a nvim &>/dev/null
    alias vim nvim
end

alias whatthecommit "curl -s https://whatthecommit.com/index.txt"
