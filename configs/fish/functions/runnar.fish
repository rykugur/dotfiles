# a simple script that pipes a list of available 'cmds' to dmenu that the user can act on

function runnar --description ''
  set -l base_dir "$HOME/.runnars"

  if test ! -d $base_dir
    echo "runnars_dir doesn't exist, returning"
    return
  end

  cd $base_dir
  set -l runnar (find -L . -type f | grep -v '^\.$' | sed 's!\.\/!!' | /usr/bin/rofi -dmenu)
  eval ./$runnar
end
