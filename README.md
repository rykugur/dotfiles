dotfiles
========

This is a very poorly named repo, as it now contains more than just dotfiles. Eventually I'll update this README. Maybe. Possibly.

Requirements
============

# base

* `fish`
* `which`
* `hostname` (arch users install package `inetutils`)

Getting Started
===============

First things first, create a symlink to the dotfiles repo you just cloned. Skip this step if you don't want to do this, but you'll need to keep that in mind for later steps.

```
cd ~
ln -s [path to dotfiles] .dotfiles
```

Then, checkout the submodule dependencies:

```
cd ~/.dotfiles
git submodule init
git submodule update
```

Install oh-my-fish:

```
~/.dotfiles/deps/oh-my-fish/bin/install
```

# Misc

## Local Config

You can create a file that is sourced on fish startup to override some base configuration. Create a file in your homedir called `.fish_local.fish` and put your custom/overrides there.

# TODO

- Work out order of import for functions.
- Update this damn readme.
