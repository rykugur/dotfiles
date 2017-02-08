#

function to.json --description "Tries to parse stdin to json; requires python"A
  set -l argc (count $argv)
  set -l os (getos)

  set -l pastecmd "xclip -o"
  if getos --mac
    set pastecmd "pbpaste"
  end

  if test $argc -ge 1
    getopts $argv | while read -l key value
      switch $key
        case p or paste or c or clip
          eval $pastecmd | python -m json.tool
      end # end switch
    end # end getopts
  else
    # default to stdin
    read -l -z line
    echo $line | python -m json.tool
  end
end
