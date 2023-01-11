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
