### randos
alias pyhttpserver "python2 -m SimpleHTTPServer 8080"
alias ts.watch "npx tsc -w"
alias rn.kill "kill -9 (lsof -t -i:8081)"

### android abbreviations
abbr --add --global adb.reverse 'adb reverse tcp:8081 tcp:8081; adb reverse tcp:8080 tcp:8080'
abbr --add --global adb.start adb shell am start
abbr --add --global adb.reset-perms adb shell pm reset-permissions
abbr --add --global .gw ./gradlew

abbr --add --global .. 'cd ..'
abbr --add --global ... 'cd ../..'
abbr --add --global .... 'cd ../../..'
abbr --add --global ..... 'cd ../../../..'
abbr --add --global agb 'ag --ignore-dir build --ignore-dir node_modules'
abbr --add --global agbt 'ag --ignore-dir build --ignore-dir node_modules --ignore-dir __tests__'
abbr --add --global fish.profile 'fish --profile-startup ./fish.profile -i -c exit'
abbr --add --global pyhttp 'python -m SimpleHTTPServer'
abbr --add --global pyjson 'python -m json.tool'
abbr --add --global cwd 'pwd | tr -d "\n" | cmd-copy'
abbr --add --global gri 'grep -i'
abbr --add --global grin 'grep -ni'
abbr --add --global grine 'grep -niRE'
abbr --add --global pwdc 'pwd | string trim | cmd-copy'
abbr --add --global ssh.forcePass 'ssh -o PreferredAuthentications=password -o PubkeyAuthentication=no'
abbr --add --global sv 'sudo nvim'
abbr --add --global taill 'tail -Fn 999'
abbr --add --global pn pnpm
abbr --add --global za 'zellij attach'
abbr --add --global zj zellij
alias kubectl kubecolor
abbr --add --global k kubectl
abbr --add --global ka 'kubectl apply'
abbr --add --global kaf 'kubectl apply -f'
abbr --add --global skaf sops-kaf
abbr --add --global kd 'kubectl describe'
abbr --add --global kdel 'kubectl delete'
abbr --add --global kdes 'kubectl describe'
abbr --add --global kg 'kubectl get'
abbr --add --global kgn 'kubectl get nodes'
abbr --add --global kgp 'kubectl get pods'
abbr --add --global kgs 'kubectl get services'
abbr --add --global kgw 'kubectl get -o wide'
abbr --add --global kgwn 'kubectl get -o wide nodes'
abbr --add --global kgwp 'kubectl get -o wide pods'
abbr --add --global kgws 'kubectl get -o wide services'
abbr --add --global kpf 'kubectl port-forward'
abbr --add --global ktx kubectx
abbr --add --global kns kubens

alias dupes "find . ! -empty -type f -exec md5sum {} + | sort | uniq -w32 -dD"
alias dush "du -sh"
alias getmyip "curl -L ifconfig.me"
alias grep "grep --color"
alias murder "kill -9"
alias ndots "cd ~/.dotfiles/; and nvim ."
alias pingtest "ping -D -O google.com"
alias replace.newlines "awk '{printf \"%s\\n\", \$0}'"
alias trim.spaces "sed -E 's/[[:space:]]+/ /g'"
alias ytdl "youtube-dl --no-playlist -x --audio-format mp3 --audio-quality 3"

alias nv nvim
alias "nv." "nvim ."
alias v nvim
alias vi nvim

###### fast travel
alias fish.local "$EDITOR $HOME/.local/fish/config.fish"

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

alias dfh duf

if which -a eza &>/dev/null
    alias ls eza
end
alias ll "command ls -al"

alias top btop
alias cat bat

alias whatthecommit "curl -s https://whatthecommit.com/index.txt"
