#

function umlauts --description "hacky script to print umlauts to wherever"
  set -l argc (count $argv)
  set -l _usage "Usage: umlauts [a|A|o|O|u|U|ss]"

  if test $argc -ge 1
    set _umlaut $argv[1]
  else
    set _umlaut (echo a\nA\no\nO\nu\nU\nss | rofi -dmenu)
  end # end if

  # ä|ö|ü|Ä|Ö|Ü|ß

  switch $_umlaut
    case a
      set _actual ä
    case A
      set _actual Ä
    case o
      set _actual ö
    case O
      set _actual Ö
    case u
      set _actual ü
    case U
      set _actual Ü
    case ss or s or B
      set _actual ß
  end # end switch

  sleep 0.1

  set -l _active_win (xdotool getactivewindow)
  # echo "executing: write_to_active_win $_actual" | tee ~/umlautslog

  # xdotool type --delay 0 --window $_active_win $_actual
  write_to_active_win $_actual
end # end function
