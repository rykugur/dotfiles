# git aliases
def gas [] {
  git status --short | lines | split column " " status file --collapse-empty | where status == MM or status == AM | each { |modified| git add $modified.file } | ignore
}
def gcu [] {
  git status --short
  | lines
  | split column " " status file --collapse-empty
  | where status == ??
  | each { |modified| rm -rf $modified.file }
  | ignore
}
alias gbn = git branch | cut -d' ' -f2
alias glg = git log --graph --pretty=format:'%Cgreen[%h]%Creset %C(white)%d%Creset %Cblue%ad by %an%Creset: %s' --date=relative
alias gll = git log --pretty=format:'%Cgreen[%H]%Creset %C(white)%d%Creset %Cblue%ad by %an%Creset: %s' --date=relative
alias git.back = git reset HEAD~1
alias git.branch = git symbolic-ref --short HEAD
alias git.clean = git branch --merged (git.branch) | grep -v (git.branch) | xargs git branch -d
alias git.lastcommit = git log | head -n1 | awk '{print \$2}'
alias git.head = gll | head -n1
alias git.track = git branch -vv
alias git.tree = git log --graph --pretty=format:'%Cgreen[%h]%Creset %C(white)%d%Creset %Cblue%ad by %an%Creset: %s' --date=relative
alias jedi = git push --force

# misc linux aliases
alias awk1 = awk '{print \$1}'
alias awk2 = awk '{print \$2}'
alias awk3 = awk '{print \$3}'
alias awk4 = awk '{print \$4}'
alias awk5 = awk '{print \$5}'
alias awk6 = awk '{print \$6}'
alias awk7 = awk '{print \$7}'
alias awk8 = awk '{print \$8}'
alias awk9 = awk '{print \$9}'
alias cat = bat
alias dfh = duf
#alias dupes = find . ! -empty -type f -exec md5sum {} + | sort | uniq -w32 -dD
alias duh = du -h
alias getmyip = dig +short myip.opendns.com @resolver1.opendns.com
alias grep = grep --color
alias ll = ls -al
alias murder = kill -9
alias nv = nvim
alias v = nvim
alias vi = nvim
alias pingtest = ping -D -O google.com
alias replace.newlines = awk '{printf \%s\\n\, \$0}'
alias tmat = sesh connect (sesh list -t | fzf)
alias top = btop
alias whatthecommit = curl -s https://whatthecommit.com/index.txt
alias ytdl = youtube-dl --no-playlist -x --audio-format mp3 --audio-quality 3

# kubernetes
alias k = kubecolor -o wide
