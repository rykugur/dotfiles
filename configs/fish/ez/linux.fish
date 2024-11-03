### arch
abbr --add --global pac pacman
abbr --add --global pacs 'pacman -S'
abbr --add --global supac 'sudo pacman'
abbr --add --global supacr 'sudo pacman -R'
abbr --add --global supacrs 'sudo pacman -Rs'
abbr --add --global supacrcs 'sudo pacman -Rcs'
abbr --add --global supacs 'sudo pacman -S'
abbr --add --global supac.remove.deps 'sudo pacman -Rcns'
abbr --add --global supac.update 'sudo pacman -Sy archlinux-keyring; and sudo pacman -Su'

### systemctl
abbr --add --global sc systemctl
abbr --add --global sc.list 'systemctl list-unit-files'
abbr --add --global sc.enabled 'systemctl list-unit-files | grep enabled'
abbr --add --global ssc 'sudo systemctl'

### tmux
abbr --add --global tm tmux
abbr --add --global tmls tmux ls
abbr --add --global tmf tmuxifier

# override/add to this env var as needed
set -gx KNOWN_TMUXIFIER_SESSIONS "sptmm\ndots"
function tmn --description "Presents the user with a list of tmux sessions to start"
    set -l selection (echo -e $KNOWN_TMUXIFIER_SESSIONS | fzf)

    # set -l local_sessions (tmux ls | awk '{print sub(/:$/,"",$1) ? $1 : $1}')

    if test -z $selection
        echo "Nothing selected"
        return
    end

    tmuxifier load-session $selection
end

if which -a sesh &>/dev/null
    alias tmat "sesh connect (sesh list -t | fzf)"
else
    abbr --add --global tmat tmux a -t
end
