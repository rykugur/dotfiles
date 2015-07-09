#

function gocd --description 'wrapper script for easier gopath navigation'
  set argc (count $argv)

  set BASE_DIR $GOPATH
  set TO_DIR ""

  if test $argc -ge 1
    switch $argv[1]
      case b or bin
        set TO_DIR "$BASE_DIR/bin"
      case s or src
        set TO_DIR "$BASE_DIR/src"

        if test $argc -ge 2
          # append a wildcard on the assumption that the user knows wtf they're doing, and just grab head
          # if they're super concerned with it they can gtfo and type it out
          # I do realize I'm primarily talking to myself. Go away.
          set TO_DIR (find $TO_DIR -name "*$argv[2]*" | head -n1)
        end
      case p or pkg
        # don't check for other args here as we might have multiple directories that begin with, for example, "linux_amd*"
        set TO_DIR "$BASE_DIR/pkg"
      case '*'
        # take a "best-effort" guess of where they want to go... likely somewhere in src
        set TO_DIR (find $BASE_DIR/src -name "*$argv[1]*" | head -n1)
    end
  else 
    # just cd to $GOPATH
    set TO_DIR $BASE_DIR
  end

  cd $TO_DIR
end
