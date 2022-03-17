### misc aliases
alias cmd.copy         "eval $COPYCMD"
alias cmd.paste        "eval $PASTECMD"
alias compare_dirs     "rsync --dry-run -v -r -c --delete"
alias cp.renamer       "curl -X GET http://$COUCHPOTATO_URL/api/$COUCHPOTATO_API_KEY/renamer.scan"
alias dupes            "find . ! -empty -type f -exec md5sum {} + | sort | uniq -w32 -dD"
alias dush             "du -sh"
alias getmyip          "dig +short myip.opendns.com @resolver1.opendns.com"
alias grep             "grep --color"
alias jsonify          "to.json -p"
alias pingtest         "ping google.com"
alias pwd.arrows       "pwd | cut -c 2- | sed 's/\\// > /g'"
alias resrc            "source $HOME/.config/fish/omf/init.fish"
alias trim.newlines    "tr -d \"\n\r\""
# working: awk '{printf "%s\\n", $0}'
alias replace.newlines "awk '{printf \"%s\\n\", \$0}'"
alias trim.spaces      "sed -E 's/[[:space:]]+/ /g'"
alias vi               "vim"
alias vimnotes         "vim -c VimwikiIndex"
alias ytdl             "youtube-dl --no-playlist -x --audio-format mp3 --audio-quality 3"

###### fast travel
alias docs      "cd $HOME/docs"
alias notes     "cd $HOME/.notes"

###### arch-specific
#alias pacdeps "pacman -Qi | sed '/^Depends On/,/^Required By/{ s/^Required By.*$//; H; d }; /^Name/!d; /^Name/{ n;x;}'| sed '/^$/s//==================================================================================/'"
alias pac.mirror "sudo reflector --verbose --country 'United States' -l 200 -p http --sort rate --save /etc/pacman.d/mirrorlist"
alias pac.update "sudo pacman -Sy archlinux-keyring; and sudo pacman -Su"
alias get.mobo "dmidecode -t 2"
###### systemd-specific
alias sclist "systemctl --type=service"
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
if which -a pydf > /dev/null 2>&1
  alias dfh "pydf"
else
  alias dfh "df -h"
end

if which -a exa > /dev/null 2>&1
  alias ls "exa"
  alias ll "exa -g --long --header --git"
else if which -a ls++ > /dev/null 2>&1
  alias ls "ls++ --potsf"
  alias ll "ls++ --potsf"
  alias llo "/usr/bin/ls -lh"
  alias lso "/usr/bin/ls"
else
  alias ll "ls -lh"
end
