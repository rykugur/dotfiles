#

function listconcattostring --description 'combines argv into a single string and returns it'
  set -l str_concat ""

  for s in $argv
    set str_concat "$str_concat $s"
  end

  echo $str_concat
end
