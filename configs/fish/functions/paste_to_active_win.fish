#

function paste_to_active_win --description "Pastes whatever is in the primary buffer to the currently active window."
  xdotool type --delay 0 --window (xdotool getactivewindow) (xsel -o)
end 
