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
        case fish or f
          set _dir "dotfiles/configs/fish"
      end # end switch
    end # end getopts
  end # end if

  cd $_base_dir/$_dir
end
