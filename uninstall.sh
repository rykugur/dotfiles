#!/usr/bin/env zsh

HOME_DIR=~

cd $HOME_DIR

# TODO: create a text file externally that the install and uninstall scripts will read from,
# instead of hard-coding these files here.
rm -f .i3 .vim .vimrc .zprezto .xinitrc .Xresources .pentadactylrc .zlogin .zlogout .zpreztorc .zprofile .zshenv .zshrc
