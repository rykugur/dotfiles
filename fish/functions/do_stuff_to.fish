#

function do_stuff_to --description 'Does stuff to the given file; Usage: do_stuff_to [filename] [stuff...]'
  set argc (count $argv)
  set usage "Usage: do_stuff_to [filename] [stuff...]\nExample usage: do_stuff_to file.txt cat file stat"

  if test $argc -ge 2
    set -l _filename $argv[1]

    for argi in (seq 2 $argc)
      echo $argv[$argi]: (eval /usr/bin/env $argv[$argi] $_filename)
      echo ===========
    end
  else 
    echo $usage
    return 1
  end
end
