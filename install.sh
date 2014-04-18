#!/usr/bin/env zsh

HOME_DIR=~
DOTFILES_DIR=$HOME_DIR/.dotfiles

cd $HOME_DIR

# TODO: create a text file externally that the install and uninstall scripts will read from,
# instead of hard-coding these files here.                               
# TODO: don't create file if it already exists?
ln -s $DOTFILES_DIR/i3 .i3
ln -s $DOTFILES_DIR/vim .vim
ln -s $DOTFILES_DIR/vimrc .vimrc
ln -s $DOTFILES_DIR/prezto .zprezto
ln -s $DOTFILES_DIR/xinitrc .xinitrc
ln -s $DOTFILES_DIR/Xresources .Xresources
ln -s $DOTFILES_DIR/pentadactylrc .pentadactylrc
ln -s $DOTFILES_DIR/prezto/runcoms/zlogin .zlogin
ln -s $DOTFILES_DIR/prezto/runcoms/zlogout .zlogout
ln -s $DOTFILES_DIR/prezto/runcoms/zpreztorc .zpreztorc
ln -s $DOTFILES_DIR/prezto/runcoms/zprofile .zprofile
ln -s $DOTFILES_DIR/prezto/runcoms/zshenv .zshenv
ln -s $DOTFILES_DIR/prezto/runcoms/zshrc .zshrc
