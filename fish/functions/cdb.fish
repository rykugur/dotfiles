#

function cdb --description 'easy-mode wrapper for \'cd ..\'; Usage: cdb #'
  set -l argc (count $argv)
  set -l usage "Usage: cdb #"

  if test $argc -eq 1
    for i in (seq 1 $argv[1])
      cd ..
    end
  else
    cd ..
  end
end
