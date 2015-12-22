#

function update_bg --description "Updates the background using feh; assumes feh is available to the user AND the DESKTOP_BG variable exists and points to an image file that feh can understand"
  if test -f ~/.desktop_bg
    feh --bg-fill ~/.desktop_bg
    return 0
  end

  if test -n $DESKTOP_BG
    feh --bg-fill $DESKTOP_BG
    return 0
  end

  return 1
end
