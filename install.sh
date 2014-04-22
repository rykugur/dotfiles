#!/usr/bin/env zsh

# TODO: likely a more "proper" way to do this?
# TODO: ruby script instead?

HOME_DIR=~
DOTFILES_DIR=$HOME_DIR/.dotfiles

if [ ! -d $DOTFILES_DIR ]; then
  # TODO: ugly
  echo "No .dotfiles dir exists, exiting"
  return
fi

cd $DOTFILES_DIR
cd prezto
git checkout master
git submodule init
git submodule update
git remote add upstream git://github.com/sorin-ionescu/prezto.git

cd $DOTFILES_DIR
cd vim/bundle/vundle
git checkout master
git remote add upstream git://github.com/gmarik/vundle.git

cd $DOTFILES_DIR
cd powerline
git checkout develop
git remote add upstream git://github.com/Lokaltog/powerline.git

cd $DOTFILES_DIR
cd powerline-fonts
git checkout master
git remote add upstream git://github.com/Lokaltog/powerline-fonts.git

cd $DOTFILES_DIR
git submodule init
git submodule update

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
