### misc
set -gx fish_user_abbreviations $fish_user_abbreviations ..='cd ..'
set fish_user_abbreviations $fish_user_abbreviations ...='cd ../..'
set fish_user_abbreviations $fish_user_abbreviations ....='cd ../../..'
set fish_user_abbreviations $fish_user_abbreviations .....='cd ../../../..'
set fish_user_abbreviations $fish_user_abbreviations cdc='cd ~/code'
set fish_user_abbreviations $fish_user_abbreviations gensshkey='ssh-keygen -t rsa -b 4096 -C "rollhax@gmail.com"'
set fish_user_abbreviations $fish_user_abbreviations pyhttp='python -m SimpleHTTPServer'
set fish_user_abbreviations $fish_user_abbreviations pyjson='python -m json.tool'
set fish_user_abbreviations $fish_user_abbreviations vimn='vim -c "VimwikiIndex"'
set fish_user_abbreviations $fish_user_abbreviations yolo='curl -s whatthecommit.com/index.txt'
# note that for this to work on OSX, you should alias xclip to pbcopy (passing the additional -i seems to be ignored)
set fish_user_abbreviations $fish_user_abbreviations cwd='pwd | tr -d "\\n" | xclip -i'
set fish_user_abbreviations $fish_user_abbreviations fn='find . -name'
set fish_user_abbreviations $fish_user_abbreviations fin='find . -iname'
set fish_user_abbreviations $fish_user_abbreviations grc='gource --stop-at-end -c 2 --disable-auto-rotate --hide filenames'
set fish_user_abbreviations $fish_user_abbreviations grn='grep -n'
set fish_user_abbreviations $fish_user_abbreviations grin='grep -ni'
set fish_user_abbreviations $fish_user_abbreviations grine='grep -niRE'
set fish_user_abbreviations $fish_user_abbreviations pagi='ps aux | grep -v grep | grep -i'
set fish_user_abbreviations $fish_user_abbreviations pwdc='pwd | tr -d "\\n" | xclip -i'
set fish_user_abbreviations $fish_user_abbreviations sv='sudo vim'
set fish_user_abbreviations $fish_user_abbreviations svec='sudo vim /etc/hosts'
set fish_user_abbreviations $fish_user_abbreviations taill='tail -Fn 999'

### arch specific
set fish_user_abbreviations $fish_user_abbreviations pac='pacman'
set fish_user_abbreviations $fish_user_abbreviations pacr='pacman -R'
set fish_user_abbreviations $fish_user_abbreviations pacrs='pacman -Rs'
set fish_user_abbreviations $fish_user_abbreviations pacrcs='pacman -Rcs'
set fish_user_abbreviations $fish_user_abbreviations pacs='pacman -S'
set fish_user_abbreviations $fish_user_abbreviations pacscc='pacman -Scc'
set fish_user_abbreviations $fish_user_abbreviations pacsyu='pacman -Syu'
set fish_user_abbreviations $fish_user_abbreviations pacsyy='pacman -Syy'
set fish_user_abbreviations $fish_user_abbreviations pacsyyu='pacman -Syyu'
set fish_user_abbreviations $fish_user_abbreviations supac='sudo pacman'
set fish_user_abbreviations $fish_user_abbreviations supacr='sudo pacman -R'
set fish_user_abbreviations $fish_user_abbreviations supacrs='sudo pacman -Rs'
set fish_user_abbreviations $fish_user_abbreviations supacrcs='sudo pacman -Rcs'
set fish_user_abbreviations $fish_user_abbreviations supacs='sudo pacman -S'
set fish_user_abbreviations $fish_user_abbreviations supacscc='sudo pacman -Scc'
set fish_user_abbreviations $fish_user_abbreviations supacsyu='sudo pacman -Syu'
set fish_user_abbreviations $fish_user_abbreviations supacsyy='sudo pacman -Syy'
set fish_user_abbreviations $fish_user_abbreviations supacsyyu='sudo pacman -Syyu'
set fish_user_abbreviations $fish_user_abbreviations supacu='sudo pacman -U'
set fish_user_abbreviations $fish_user_abbreviations sc='systemctl'
set fish_user_abbreviations $fish_user_abbreviations sce='systemctl enable --now'
set fish_user_abbreviations $fish_user_abbreviations scd='systemctl disable --now'
set fish_user_abbreviations $fish_user_abbreviations scr='systemctl restart'
set fish_user_abbreviations $fish_user_abbreviations scs='systemctl start'
set fish_user_abbreviations $fish_user_abbreviations scst='systemctl status'
set fish_user_abbreviations $fish_user_abbreviations ssc='sudo systemctl'
set fish_user_abbreviations $fish_user_abbreviations ssce='sudo systemctl enable --now'
set fish_user_abbreviations $fish_user_abbreviations sscd='sudo systemctl disable --now'
set fish_user_abbreviations $fish_user_abbreviations sscr='sudo systemctl restart'
set fish_user_abbreviations $fish_user_abbreviations sscs='sudo systemctl start'
set fish_user_abbreviations $fish_user_abbreviations sscst='sudo systemctl status'

### git specific
set fish_user_abbreviations $fish_user_abbreviations ga='git add'
set fish_user_abbreviations $fish_user_abbreviations ga.='git add .'
set fish_user_abbreviations $fish_user_abbreviations gas='git add (git status --short | grep -E "(AM|MM)" | awk \'{print $2}\')'
set fish_user_abbreviations $fish_user_abbreviations gau='git add -u'
set fish_user_abbreviations $fish_user_abbreviations gb='git branch'
set fish_user_abbreviations $fish_user_abbreviations gbc='git branch --contains'
set fish_user_abbreviations $fish_user_abbreviations gbD='git branch -D'
set fish_user_abbreviations $fish_user_abbreviations gbm='git branch --merged'
set fish_user_abbreviations $fish_user_abbreviations gbr='git branch -r'
set fish_user_abbreviations $fish_user_abbreviations gc='git commit'
set fish_user_abbreviations $fish_user_abbreviations gca='git commit --amend'
set fish_user_abbreviations $fish_user_abbreviations gcm='git commit -m'
set fish_user_abbreviations $fish_user_abbreviations gcm.='git commit -m "."'
set fish_user_abbreviations $fish_user_abbreviations gcmyolo='git commit -m (curl -s whatthecommit.com/index.txt); and git push'
set fish_user_abbreviations $fish_user_abbreviations gco='git checkout'
set fish_user_abbreviations $fish_user_abbreviations gco.='git checkout .'
set fish_user_abbreviations $fish_user_abbreviations gcob='git checkout -b'
set fish_user_abbreviations $fish_user_abbreviations gcp='git cherry-pick'
set fish_user_abbreviations $fish_user_abbreviations gcu='rm -rf (git status --short | grep "??" | cut -d" " -f2)'
set fish_user_abbreviations $fish_user_abbreviations gd='git diff'
set fish_user_abbreviations $fish_user_abbreviations gds='git diff --staged'
set fish_user_abbreviations $fish_user_abbreviations gf='git fetch'
set fish_user_abbreviations $fish_user_abbreviations gfp='git fetch -p'
set fish_user_abbreviations $fish_user_abbreviations gg='git grep --color=auto -n'
set fish_user_abbreviations $fish_user_abbreviations ggi='git grep --color=auto -ni'
set fish_user_abbreviations $fish_user_abbreviations gl='git log'
set fish_user_abbreviations $fish_user_abbreviations glo='git log --oneline'
set fish_user_abbreviations $fish_user_abbreviations gpl='git pull'
set fish_user_abbreviations $fish_user_abbreviations gps='git push'
set fish_user_abbreviations $fish_user_abbreviations gpsf='git push --force'
set fish_user_abbreviations $fish_user_abbreviations gpssuo='git push --set-upstream origin'
set fish_user_abbreviations $fish_user_abbreviations gpls='git pull; and git push'
set fish_user_abbreviations $fish_user_abbreviations gpub='git push -u origin (_git_branch_name)'
set fish_user_abbreviations $fish_user_abbreviations grb='git rebase'
set fish_user_abbreviations $fish_user_abbreviations grbc='git rebase --continue'
set fish_user_abbreviations $fish_user_abbreviations gr='git reset'
set fish_user_abbreviations $fish_user_abbreviations grh='git reset HEAD'
set fish_user_abbreviations $fish_user_abbreviations grhh='git reset --hard HEAD'
set fish_user_abbreviations $fish_user_abbreviations grm='git remote'
set fish_user_abbreviations $fish_user_abbreviations grv='git remote -v'
set fish_user_abbreviations $fish_user_abbreviations gss='git status --short'
