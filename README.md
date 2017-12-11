dotfiles
========

This is a very poorly named repo, as it now contains more than just dotfiles. Eventually I'll update this README. Maybe. Possibly.

Requirements
============

# base

* dmenu2
* feh
* urxvt (rxvt-unicode)
* compton
* xdotool
* pactl
* playerctl
* xorg-xbacklight

# for i3

* i3blocks

# for openbox

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

Install oh-my-fish:

```
~/.dotfiles/deps/oh-my-fish/bin/install
```

Install fisher (subject to change, check the fisherman README.md):

```
curl -Lo ~/.config/fish/functions/fisher.fish --create-dirs git.io/fisher
fisher install
```

Create some symlinks (assumes ~/.dotfiles exists)

```
~/.dotfiles/misc/scripts/create_symlinks.fish
```

Optional but useful symlinks:

```
ln -s /path/to/desktop/background/img .desktop_bg
```

# Misc

## Local Config

You can create a file that is sourced on fish startup to override some base configuration. Create a file in your homedir called `.fish_local.fish` and put your custom/overrides there.

## Install ls++

```
cd /path/to/dotfiles/deps/Term-ExtendedColor
perl Makefile.PL
make
make test
sudo make install
cd ~
```

If you didn't run `create_symlinks.fish` earlier:

```
ln -s /path/to/dotfiles/configs/ls++.conf ~/.ls++.conf
```

# TODO

- Work out order of import for functions.
- Update this damn readme.
