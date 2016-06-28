#

function diaf --description "Dumbfire kill app. This exists because pgrep is tarded. Usage: diaf [app]"
  set -l argc (count $argv)
  set -l _usage "Usage: diaf [app]"

  if test $argc -ne 1
    echo Missing arg. $_usage
    return 1
  end

  kill (ps aux | grep -v grep | grep -i $argv | awk '{print $2}')
end
