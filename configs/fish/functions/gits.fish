#

function gits --description "cd wrapper for gits dir"
  set -l argc (count $argv)
  set -l _usage "Usage: gits [dir]"

  if test -z $GITS
    echo "GITS env variable not set, exiting"
    return 1
  end

  set -l _base_dir $GITS
  set -l _dir ""

  if test $argc -ge 1
    getopts $argv | while read -l key value
      switch $key
        case sync or s
          set _dir "sync"
        case dotfiles or df or dots or d
          set _dir "dotfiles"
        case configs or conf or c
          set _dir "dotfiles/configs"
        case fish or f
          set _dir "dotfiles/configs/fish"
      end # end switch
    end # end getopts
  end # end if

  cd $_base_dir/$_dir
end

complete -f -c gits -n 'gits' -a --sync
complete -f -c gits -n 'gits' -a --dotfiles
complete -f -c gits -n 'gits' -a --configs
complete -f -c gits -n 'gits' -a --fish
