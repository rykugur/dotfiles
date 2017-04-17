#!/usr/bin/env fish
# Yes, fish is a dependency. No, I don't care.

# just removes/(re-)creates symlinks to dotfiles
# be damn sure about this before calling, as you'll p(ossi|roba)bly lose things

# TODO: dry-run?

set -l DOTFILES_DIR "$HOME/.dotfiles"
if test ! -d $DOTFILES_DIR
  echo "dotfiles dir doesn't exist, exiting"
  exit 1
end

# brute force it, YEAH!!

rm $HOME/.config/fish/config.fish
rm $HOME/.compton.conf
rm $HOME/.dunstrc
rm $HOME/.gitconfig
rm $HOME/.i3
rm $HOME/.ls++.conf
rm $HOME/.config/openbox
rm $HOME/.tmux.conf
rm $HOME/.vim
rm $HOME/.vimrc
rm $HOME/.xbindkeysrc
rm $HOME/.xinitrc
rm $HOME/.Xresources

ln -s $DOTFILES_DIR/configs/fish/config.fish $HOME/.config/fish/config.fish
ln -s $DOTFILES_DIR/configs/compton.conf $HOME/.compton.conf
ln -s $DOTFILES_DIR/configs/dunstrc $HOME/.dunstrc
ln -s $DOTFILES_DIR/configs/gitconfig $HOME/.gitconfig
ln -s $DOTFILES_DIR/configs/i3 $HOME/.i3
ln -s $DOTFILES_DIR/configs/ls++.conf $HOME/.ls++.conf
ln -s $DOTFILES_DIR/configs/openbox $HOME/.config/openbox
ln -s $DOTFILES_DIR/configs/tmux.conf $HOME/.tmux.conf
ln -s $DOTFILES_DIR/configs/vim $HOME/.vim
ln -s $DOTFILES_DIR/configs/vimrc $HOME/.vimrc
ln -s $DOTFILES_DIR/configs/x/xbindkeysrc $HOME/.xbindkeysrc
ln -s $DOTFILES_DIR/configs/x/xinitrc $HOME/.xinitrc
ln -s $DOTFILES_DIR/configs/x/Xresources $HOME/.Xresources

echo "Don't forget to set your desktop background, e.g. \"ln -s /path/to/background/image ~/.desktop_bg\"".
