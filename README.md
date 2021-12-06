dotfiles
========

This is a very poorly named repo, as it now contains more than just dotfiles. Eventually I'll update this README. Maybe. Possibly.

Requirements
============

## Terminal

* `fish`
* [`oh-my-fish`](https://github.com/oh-my-fish/oh-my-fish) (optional)
* `git`
* a font with a wide array of icons and symbols; see [Nerd Fonts](https://www.nerdfonts.com) to get your favorite font patched with extra symbols. Iosevka is used specifically in this repo.

## Sway

* `sway`
* `brightnessctl`
* `dmenu`

### Optional

* `which`
* `hostname` (arch users install package `inetutils`)
* `curl`
* [`exa`](https://github.com/ogham/exa)
* [`starship`](https://starship.rs)

## Vim

* [`vundle`](https://github.com/VundleVim/Vundle.vim)

Installation
============

* Ensure you have the requirements listed above.
* Ensure that fish exists on your path: `which -a fish`
* If on a mac, and using homebrew, add brew to your path: `set PATH /opt/homebrew/bin $PATH`
* Create symlink to `[dotfiles]/configs/omf` in your `$HOME/.config` directory: `ln -s [dotfiles]/configs/fish/omf $HOME/.config/omf`
* Install OMF: `./misc/scripts/install_omf.fish`
* (optional) Run `./scripts/intall_vundle.fish`.
* (optional) Install vim plugins: `vim +BundleInstall`

Local Config
============

OMF allows a custom local configuration file. Use this file for anything that needs to be local only to your current device, or to override some base configuration. Create a file called `$HOME/.fish_local.fish` and put your custom/overrides there.

In order for this to work, ensure that `$HOME/.config/omf` is pointing to your OMF config directory OR the `[dotfiles]/configs/omf` directory.

# TODO
