#

function cdc --description "cdcode"
  if not set -q CODE_DIR
    echo "CODE_DIR env var not set, exiting"
    return 1
  end

  set -l argc (count $argv)
  set -l _usage "cdc: aka cdcode, cd to code or subdir. Usage: cdc [a|android|g|go]"
  # sane default
  set -l _target_dir "$CODE_DIR"

  if test $argc -gt 0
    getopts $argv | while read -l key value
      switch $key
        case a or android
          set _target_dir "$CODE_DIR/android"
        case g or go
          set _target_dir "$CODE_DIR/go"
        case h or help
          echo $_usage
          return 0
      end # end switch
    end # end getopts
  end

  if not test -d $_target_dir
    echo "_target_dir=$_target_dir doesn't exist, exiting"
    return 1
  end

  cd $_target_dir
end
