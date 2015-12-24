#

function write_to_active_win --description "Writes whatever is passed in to the currently active window."
  xdotool type --delay 0 --window (xdotool getactivewindow) $argv
end 
