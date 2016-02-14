#!/usr/bin/fish
# Yes, fish is a dependency. No, I don't care.

# just removes/(re-)creates symlinks to dotfiles
# be damn sure about this before calling, as you'll possibly lose things

set -l argc (count $argv)
set -l DOTFILES_DIR ""
if test $argc -eq 1
  # try to use the given arg as dotfiles path
  set DOTFILES_DIR $argv[1]
else
  set DOTFILES_DIR "$HOME/.dotfiles"
end

if test ! -d $DOTFILES_DIR
  echo "Specified dotfiles dir didn't exist, exiting; DOTFILES_DIR=$DOTFILES_DIR"
  exit 1
end

exit 1

# brute force it, YEAH!!

rm $HOME/.compton.conf
rm $HOME/.dunstrc
rm $HOME/.config/fish/config.fish
rm $HOME/.gitconfig
rm $HOME/.i3
rm $HOME/.ls++.conf
rm $HOME/.config/openbox
rm $HOME/.pentadactylrc
rm $HOME/.config/ranger
rm $HOME/.tmux.conf
rm $HOME/.vim
rm $HOME/.vimrc
rm $HOME/.xbindkeysrc
rm $HOME/.xinitrc
rm $HOME/.Xresources

# if [ ! -e $HOME/.pentadactylrc.local ]; then
#   touch $HOME/.pentadactylrc.local
# fi
# if [ ! -e $HOME/.xinitrc.local ]; then
#   touch $HOME/.xinitrc.local
# fi

echo "Don't forget to set your desktop background, e.g. \"ln -s /path/to/background/image ~/.desktop_bg\"".
