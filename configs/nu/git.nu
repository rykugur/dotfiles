def gas [] {
  git status --short | lines | split column " " status file --collapse-empty | where status == MM or status == AM | each { |modified| git add $modified.file } | ignore
}

def "git checkout" [branch?: string] {
  if ($branch | is-not-empty) {
    ^git checkout $branch
  } else {
    ^git checkout (git branch | fzf | str replace '*' '' | str trim)
  }
}

def gcu [] {
  git status --short
  | lines
  | split column " " status file --collapse-empty
  | where status == ??
  | each { |modified| rm -rf $modified.file }
  | ignore
}

alias gits = cd $"($env.HOME)/gits"

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

$env.abbreviations = $env.abbreviations | merge {
  ga: "git add"
  ga.: "git add ."
  gau: "git add -u"
  gb: "git branch"
  gbc: "git branch --contains"
  gbD: "git branch -D"
  gbm: "git branch -m"
  gbr: "git branch -r"
  gc: "git commit"
  gca: "git commit --amend"
  gcm: "git commit -m"
  gcmwip: "git commit -m wip"
  gco: "git checkout"
  gco.: "git checkout ."
  gcob: "git checkout -b"
  gcof: "git checkout (git branch | fzf | str trim)"
  gcp: "git cherry-pick"
  gcy: "git commit -m (curl -s https://whatthecommit.com/index.txt)"
  gd: "git diff"
  gds: "git diff --staged"
  gf: "git fetch"
  gfp: "git fetch -p"
  gg: "git grep --color auto -n"
  ggi: "git grep --color auto -ni"
  gl: "git log"
  glo: "git log --oneline"
  glss: "git ls-files --stage"
  gpl: "git pull"
  gps: "git push"
  gpsf: "git push --force"
  gpssuo: "git push --set-upstream origin"
  gpls: "git pull; and git push"
  gpub: "git push -u origin (git.branch)"
  grb: "git rebase"
  grbc: "git rebase --continue"
  grpo: "git remote prune origin"
  gr: "git reset"
  grh: "git reset HEAD"
  grhh: "git reset --hard HEAD"
  grho: "git reset --hard origin/(git.branch)"
  grm: "git remote"
  grv: "git remote -v"
  gss: "git status --short"
  #gss: 'git status --short | lines | str trim | split column " "'
  gssg: "git status --short | grep"
  gsub: "git submodule"
  gw: "git worktree"
  gwa: "git worktree add"
  gwr: "git worktree remove"
  gwls: "git worktree list"
  turtles: "git commit -m \"it's turtles all the way down\""
}
