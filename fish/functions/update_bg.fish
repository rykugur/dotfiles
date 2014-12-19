#

function update_bg --description "Updates the background using feh; assumes feh is available to the user AND the DESKTOP_BG variable exists and points to an image file that feh can understand"
  if test -n $DESKTOP_BG
    feh --bg-fill ~/.dotfiles/backgrounds/mieke_at_emmas.jpg
  end
end
