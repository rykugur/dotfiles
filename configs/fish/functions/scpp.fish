#

function scpp --description "scp some file from some box to current dir, should use the local host's ssh config/keys; Usage: scpp [host] [space separated list of files]"
  set -l argc (count $argv)
  set -l usage "scpp [host] [space separated list of files]"

  if test $argc -ge 2
    set -l host $argv[1]

    if host $host >> /dev/null
      # host exists, go ahead and try
      set -l files $argv[2..$argc]

      for file in $files
        scp $host:$file .
      end
    end
  else
    echo "invalid args; Usage: $usage"
  end
end
