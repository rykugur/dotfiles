#

function gits --description "cd wrapper for gits dir"
  set -l argc (count $argv)
  set -l _base_dir "$HOME/gits"
  set -l _usage "Usage: gits [dir]"

  if test $argc -lt 1
    echo $_usage
  end

  # set a sane default
  set -l _dir "dotfiles"
  switch $argv[1]
  case sync or s
    set _dir "sync"
  case dotfiles or df or dots or d
    set _dir "dotfiles"
  end # end switch

  cd $_base_dir/$_dir
end
