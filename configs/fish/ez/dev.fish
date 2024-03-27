### randos
alias pyhttpserver "python2 -m SimpleHTTPServer 8080"
alias ts.watch "npx tsc -w"
alias rn.kill "kill -9 (lsof -t -i:8081)"

### android abbreviations
abbr --add --global adb.reverse 'adb reverse tcp:8081 tcp:8081; adb reverse tcp:8080 tcp:8080'
abbr --add --global adb.start adb shell am start
abbr --add --global adb.reset-perms adb shell pm reset-permissions
abbr --add --global .gw ./gradlew

### git
abbr --add --global ga 'git add'
abbr --add --global ga. 'git add .'
abbr --add --global gas 'git add (git status --short | grep -E "(AM|MM)" | awk \'{print $2}\')'
abbr --add --global gau 'git add -u'
abbr --add --global gb 'git branch'
abbr --add --global gbc 'git branch --contains'
abbr --add --global gbD 'git branch -D'
abbr --add --global gbm 'git branch -m'
abbr --add --global gbr 'git branch -r'
abbr --add --global gc 'git commit'
abbr --add --global gca 'git commit --amend'
abbr --add --global gcm 'git commit -m'
abbr --add --global gcmwip 'git commit -m wip'
abbr --add --global gcm.yolo 'git commit -m (curl -s https://whatthecommit.com/index.txt)'
abbr --add --global gco 'git checkout'
abbr --add --global gco. 'git checkout .'
abbr --add --global gcob 'git checkout -b'
abbr --add --global gcp 'git cherry-pick'
abbr --add --global gcu 'rm -rf (git status --short | grep "??" | cut -d" " -f2)'
abbr --add --global gd 'git diff'
abbr --add --global gds 'git diff --staged'
abbr --add --global gf 'git fetch'
abbr --add --global gfp 'git fetch -p'
abbr --add --global gg 'git grep --color auto -n'
abbr --add --global ggi 'git grep --color auto -ni'
abbr --add --global gits 'cd $HOME/gits'
abbr --add --global gl 'git log'
abbr --add --global glo 'git log --oneline'
abbr --add --global glss 'git ls-files --stage'
abbr --add --global gpl 'git pull'
abbr --add --global gps 'git push'
abbr --add --global gpsf 'git push --force'
abbr --add --global gpssuo 'git push --set-upstream origin'
abbr --add --global gpls 'git pull; and git push'
abbr --add --global gpub 'git push -u origin (git.branch)'
abbr --add --global grb 'git rebase'
abbr --add --global grbc 'git rebase --continue'
abbr --add --global gr 'git reset'
abbr --add --global grh 'git reset HEAD'
abbr --add --global grhh 'git reset --hard HEAD'
abbr --add --global grho 'git reset --hard origin/(git.branch)'
abbr --add --global grm 'git remote'
abbr --add --global grv 'git remote -v'
abbr --add --global gss 'git status --short'
abbr --add --global gssg 'git status --short | grep'
abbr --add --global gsub 'git submodule'
abbr --add --global turtles 'git commit -m "it\'s turtles all the way down"'
alias gbn "git branch | cut -d' ' -f2"
alias glg "git log --graph --pretty=format:'%Cgreen[%h]%Creset %C(white)%d%Creset %Cblue%ad by %an%Creset: %s' --date=relative"
alias gll "git log --pretty=format:'%Cgreen[%H]%Creset %C(white)%d%Creset %Cblue%ad by %an%Creset: %s' --date=relative"
alias gls "git log --topo-order --stat --pretty=format:\"%C(bold)Commit:%C(reset) %C(green)%H%C(red)%d%n%C(bold)Author:%C(reset) %C(cyan)%an <%ae>%n%C(bold)Date:%C(reset)   %C(blue)%ai (%ar)%C(reset)%n%+B\""
alias git.back "git reset HEAD~1"
alias git.branch "git symbolic-ref --short HEAD"
alias git.clean "git branch --merged (git.branch) | grep -v (git.branch) | xargs git branch -d"
alias git.lastcommit "git log | head -n1 | awk '{print \$2}' | trim.newlines"
alias git.head "gll | head -n1"
alias git.track "git branch -vv"
alias git.tree "log --graph --pretty=format:'%Cgreen[%h]%Creset %C(white)%d%Creset %Cblue%ad by %an%Creset: %s' --date=relative"
alias jedi "git push --force"
