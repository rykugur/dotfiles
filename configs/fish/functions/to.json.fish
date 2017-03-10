#

function to.json --description "Tries to parse stdin to json; requires python"
  set -l argc (count $argv)

  if test $argc -ge 1
    getopts $argv | while read -l key value
      switch $key
        case p or paste or c or clip
          eval $PASTECMD | python -m json.tool
      end # end switch
    end # end getopts
  else
    # default to stdin
    read -l -z json
    echo $json | python -m json.tool
  end
end
