dotfiles
========

This is a very poorly named repo, as it now contains more than just dotfiles. Eventually I'll update this README. Maybe. Possibly.

Local Config
============

Create a file in your homedir called ".fish_local.fish" for any local config. Gets loaded last so as to overwrite any base config.

Symlinks
========

The following is a list of files that need to be symlinked in your homedir (unless otherwise indicated) to work:

```
ln -s ~/.dotfiles/configs/Xresources .Xresources
ln -s ~/.dotfiles/configs/xinitrc .xinitrc
ln -s ~/.dotfiles/configs/i3 .i3
ln -s ~/.dotfiles/configs/configs/i3/i3blocks.conf .i3blocks.conf
ln -s ~/.dotfiles/oh-my-fish .oh-my-fish
ln -s ~/.dotfiles/vim .vim
ln -s ~/.dotfiles/configs/vimrc .vimrc
ln -s ~/.dotfiles/configs/fish/config.fish ~/.config/fish/config.fish
```

The following are optional:

```
ln -s ~/.dotfiles/configs/ls++.conf .ls++.conf
ln -s /path/to/desktop/background/img .desktop_bg
ln -s ~/.dotfiles/configs/tmux.conf .tmux.conf
ln -s /path/to/runnars .runnars
ln -s /path/to/snippets .snippets
```
