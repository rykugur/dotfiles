### misc abbreviations

abbr --add --global .. 'cd ..'
abbr --add --global ... 'cd ../..'
abbr --add --global .... 'cd ../../..'
abbr --add --global ..... 'cd ../../../..'
abbr --add --global agb 'ag --ignore-dir build --ignore-dir node_modules'
abbr --add --global agbt 'ag --ignore-dir build --ignore-dir node_modules --ignore-dir __tests__'
abbr --add --global fish.profile 'fish --profile-startup ./fish.profile -i -c exit'
abbr --add --global gensshkey 'ssh-keygen -t rsa -b 4096 -C "rollhax@gmail.com"'
abbr --add --global pyhttp 'python -m SimpleHTTPServer'
abbr --add --global pyjson 'python -m json.tool'
abbr --add --global vimn 'vim -c "VimwikiIndex"'
abbr --add --global yolo 'curl -s whatthecommit.com/index.txt'
abbr --add --global cwd 'pwd | trim.newlines | cmd.copy'
abbr --add --global fn 'find . -name'
abbr --add --global fin 'find . -iname'
abbr --add --global grc 'gource --stop-at-end -c 2 --disable-auto-rotate --hide filenames'
abbr --add --global gri 'grep -i'
abbr --add --global grin 'grep -ni'
abbr --add --global grine 'grep -niRE'
abbr --add --global gw './gradlew'
abbr --add --global pagi 'ps aux | grep -v grep | grep -i'
abbr --add --global pwdc 'pwd | trim.newlines | cmd.copy'
abbr --add --global sv 'sudo nvim'
abbr --add --global taill 'tail -Fn 999'
