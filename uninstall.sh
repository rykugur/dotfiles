#!/usr/bin/env zsh

HOME_DIR=~

cd $HOME_DIR

# TODO: create a text file externally that the install and uninstall scripts will read from,
# instead of hard-coding these files here.
rm -f .i3 .vim .vimrc .xinitrc .Xresources .zprezto .zlogin .zlogout .zpreztorc .zprofile .zshenv .zshrc
