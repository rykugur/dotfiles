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

