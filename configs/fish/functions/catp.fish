#

function catp --description 'cats the given file to the primary selection buffer'
  set -l argc (count $argv)
  set -l _usage "cats the contents of the given file to the primary selection buffer. Usage: catp [file]"

  if test $argc -lt 1
    echo $_usage
    return 1
  end

  if test ! -f $argv
    echo "Specified path wasn't a file; path=$argv"
    return 1
  end

  set -l _arch (uname)
  if test $_arch = "Darwin"
    cat $argv | pbcopy
  else
    cat $argv | xclip -i
  end
end
