#

function ternary --description "Returns the value of the first arg if non-empty/non-null, else the second (default) arg value."
  set -l argc (count $argv)

  if test $argc -eq 2
    set -l _first $argv[1]
    set -l _default $argv[2]

    if test -z $_first
      echo $_default
      return 0
    end

    echo $_first
    return 0
  else if test $argc -eq 1
    echo $argv
  else
    echo "Invalid arguments, Usage: ternary arg1 arg2"
  end
end
