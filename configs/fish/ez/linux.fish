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

### bspwm
abbr --add --global bspq bspc query

### docker
abbr --add --global dc docker-compose
abbr --add --global dcb docker-compose build
abbr --add --global dcr docker-compose restart
abbr --add --global dcu docker-compose up
abbr --add --global dcud docker-compose up -d
abbr --add --global dcd docker-compose down
abbr --add --global drit 'docker run -it'
abbr --add --global docker.clean 'docker rmi (docker images -f dangling=true -q)'
abbr --add --global lzd lazydocker

### hyprland
abbr --add --global hypr.log tail -Fn 999 /tmp/hypr/$HYPRLAND_INSTANCE_SIGNATURE/hyprland.log

### tmux
abbr --add --global tmat tmux a -t
abbr --add --global tmnew tmux new
abbr --add --global tms tmux new -s
abbr --add --global tmls tmux ls
abbr --add --global tmx tmuxinator
abbr --add --global tmxs tmuxinator start
