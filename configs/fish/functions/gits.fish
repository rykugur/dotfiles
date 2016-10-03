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
  if test $argc -gt 0
    switch $argv[1]
    case sync or s
      set _dir "sync"
    case dotfiles or df or dots or d
      set _dir "dotfiles"
    end # end switch
  end # end if

  cd $_base_dir/$_dir
end
