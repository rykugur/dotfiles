#

function len --description "Prints the length of the given string. Usage: len \"some string\""
  set -l argc (count $argv)
  set -l _usage "Usage: len \"some string\""

  if test $argc -lt 1
    echo $_usage
  end
end
