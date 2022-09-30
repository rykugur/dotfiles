# dotfiles

This is a very poorly named repo, as it now contains more than just dotfiles. Eventually I'll update this README. Maybe. Possibly.

# Installation

## Terminal

- Install fish: https://fishshell.com/
- Ensure fish exists on your path: `which -a fish`
  - If on a mac, and using homebrew, add brew to your path: `PATH=/opt/homebrew/bin:$PATH`
- Set fish as your default shell: `chsh -s $(which -a fish)`
  - This is optional, fish can be manually started from a bash shell.
- Create symlink to omf config: `ln -s [dotfiles]/configs/fish/omf $HOME/.config/omf`
- Install OMF: `./misc/scripts/install_omf.fish`
- Install [`exa`](https://github.com/ogham/exa)
- Install [`starship`](https://starship.rs)

### Local Config

OMF allows a custom local configuration file. Use this file for anything that needs to be local only to your current device, or to override some base configuration. Create folder: `mkdir -p $HOME/.local/fish`. Inside this folder you can place a `config.fish` file for any custom local overrides, and you can create a `functions` directory for any local-only custom (override) functions.

In order for this to work, ensure that `$HOME/.config/omf` is pointing to your OMF config directory.

## Vim

- Install vim
- Use the included scripts to install `vundle`:
  - Run `./misc/scripts/intall_vundle.fish`.
- Sym-link vimrc: `ln -s [dotfiles]/configs/vimrc $HOME/.vimrc`
- Install vim plugins: `vim +BundleInstall`
