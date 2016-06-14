dotfiles
========

This is a very poorly named repo, as it now contains more than just dotfiles. Eventually I'll update this README. Maybe. Possibly.

Requirements
============

# base

dmenu2
feh
urxvt (rxvt-unicode)
compton
i3blocks
xdotool
pactl
playerctl
xorg-xbacklight

# for i3

# for openbox

lemonbar-xft
acpi

# Optional

password-store (``git clone https://git.zx2c4.com/password-store``) - place password-store/contrib/dmenu/passmenu somewhere on the path.

Getting Started
===============

First things first, create a symlink to the dotfiles repo you just cloned. Skip this step if you don't want to do this, but you'll need to keep that in mind for later steps.

```
cd ~
ln -s [path to dotfiles] .dotfiles
```

Then, checkout the submodule dependencies:

```
git submodule init
git submodule update
```

Then, you need to make some symlinks:

```
ln -s ~/.dotfiles/configs/Xresources .Xresources
ln -s ~/.dotfiles/configs/xinitrc .xinitrc
ln -s ~/.dotfiles/configs/i3 .i3
ln -s ~/.dotfiles/configs/configs/i3/i3blocks.conf .i3blocks.conf
ln -s ~/.dotfiles/configs/i3/scripts pixellock /usr/bin/pixellock
ln -s ~/.dotfiles/configs/vim .vim
ln -s ~/.dotfiles/configs/vimrc .vimrc
ln -s ~/.dotfiles/deps/configs/ls++.conf .ls++.conf
```

After that, hacky step; install oh-my-fish, then create a symlink.

```
cd ~/.dotfiles/deps/oh-my-fish/bin
./install
cd ~
ln -s ~/.dotfiles/configs/fish/config.fish ~/.config/fish/config.fish
```

Finally, edit ``$HOME/.config/fish/config.fish``, uncomment and set your OMF_CONFIG path and run `omf install`.

Optional but useful symlinks:

```
ln -s /path/to/desktop/background/img .desktop_bg
ln -s ~/.dotfiles/configs/tmux.conf .tmux.conf

ln -s /path/to/runnars .runnars
ln -s /path/to/snippets .snippets

# to replace the bobthefish prompt
rm ~/.config/fish/functions/fish_prompt.fish
ln -s ~/.dotfiles/configs/fish/omf/fish_prompt_bobthefish.fish ~/.config/fish/functions/fish_prompt.fish

# overwrite certain odd functionality in some themes
# TODO: this can be resolved by fixing the order in which we append to fish_function_path, so then I won't
# need to concern myself with doing this at all
ln -s ~/.dotfiles/configs/fish/functions/fish_title.fish ~/.config/fish/functions/fish_title.fish
ln -s ~/.dotfiles/configs/fish/functions/prompt_pwd.fish ~/.config/fish/functions/prompt_pwd.fish
```

# Local Config

You can create a file that is sourced on fish startup to override some base configuration. Create a file in your homedir called ".fish_local.fish" and put your custom/overrides there.

# TODO

- Work out order of import for functions.
