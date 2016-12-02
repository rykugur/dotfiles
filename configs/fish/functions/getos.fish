#

function getos --description "Returns the current os kernel (uname) OR true/false for given arg. Usage: getos [--linux|--mac|--win]"
  set -l argc (count $argv)
  set -l _uname (uname)

  if test $argc -ge 1
    set -l _expected_uname

    getopts $argv | while read -l key value
      switch $key
        case l or linux
          set _expected_uname "Linux"
        case m or d or mac or darwin
          set _expected_uname "Darwin"
        case w or win
          set _expected_uname "Windows" # ???
      end

      if test $_uname = $_expected_uname
        return 0
      else
        return 1
      end
    end
  else
    # just return uname
    echo (uname)
  end
end
