#

function get_last_arg --description 'returns the final arg from the given list'
  set -l argc (count $argv)

  if test $argc -gt 0
    echo $argv[$argc]
  end
end
