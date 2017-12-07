#

function dots --description "cd wrapper for dots dir"
  set -l argc (count $argv)
  set -l _usage "Usage: dots"

  if test -z $DOTFILES_DIR
    echo "DOTFILES_DIR env variable not set, exiting"
    return 1
  end

  if test ! -d $DOTFILES_DIR
    echo "DOTFILES_DIR doesn't exist, exiting"
    return 1
  end

  set -l _base_dir $DOTFILES_DIR
  set -l _dir ""

  if test $argc -ge 1
    getopts $argv | while read -l key value
      switch $key
        case configs or c
          set _dir "configs"
        case fish or f
          set _dir "configs/fish"
      end # end switch
    end # end getopts
  end # end if

  cd $_base_dir/$_dir
end

complete -f -c dots -n 'dots' -a --configs
complete -f -c dots -n 'dots' -a --fish
