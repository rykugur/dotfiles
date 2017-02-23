#

function update_xrdb --description "Updates Xresources via xrdb"
  xrdb -I$HOME/.dotfiles/configs/x/ $HOME/.Xresources
end
