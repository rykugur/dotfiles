### misc abbreviations

abbr --add --global .. 'cd ..'
abbr --add --global ... 'cd ../..'
abbr --add --global .... 'cd ../../..'
abbr --add --global ..... 'cd ../../../..'
abbr --add --global gensshkey 'ssh-keygen -t rsa -b 4096 -C "rollhax@gmail.com"'
abbr --add --global pyhttp 'python -m SimpleHTTPServer'
abbr --add --global pyjson 'python -m json.tool'
abbr --add --global vimn 'vim -c "VimwikiIndex"'
abbr --add --global yolo 'curl -s whatthecommit.com/index.txt'
abbr --add --global cwd 'pwd | trim.newlines | cmd.copy'
abbr --add --global fn 'find . -name'
abbr --add --global fin 'find . -iname'
abbr --add --global grc 'gource --stop-at-end -c 2 --disable-auto-rotate --hide filenames'
abbr --add --global grn 'grep -n'
abbr --add --global grin 'grep -ni'
abbr --add --global grine 'grep -niRE'
abbr --add --global pagi 'ps aux | grep -v grep | grep -i'
abbr --add --global pwdc 'pwd | trim.newlines | cmd.copy'
abbr --add --global sv 'sudo vim'
abbr --add --global svec 'sudo vim /etc/hosts'
abbr --add --global taill 'tail -Fn 999'

if which -a ag &> /dev/null
  abbr --add --global agb 'ag --ignore build'
end