#

function get_last_arg --description 'returns the final arg from the given list'
  set -l argc (count $argv)

  echo $argv[$argc]
end
