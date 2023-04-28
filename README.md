# dotfiles

This is a very poorly named repo, as it now contains more than just dotfiles. Eventually I'll update this README. Maybe. Possibly.

# Installation

## Terminal

- Install [fish shell](https://fishshell.com/) (should be in your distro's repositories).
- Ensure fish exists on your path: `which -a fish`
  - If on a mac, and using homebrew, add brew to your path: `PATH=/opt/homebrew/bin:$PATH`
- Set fish as your default shell: `chsh -s $(which -a fish)`
  - This is optional, fish can be manually started from a bash shell.
- Create symlink to omf config: `ln -s [dotfiles]/configs/fish/omf $HOME/.config/omf`
- Install OMF: `./misc/scripts/install_omf.fish`
- (Optional) Install [`exa`](https://github.com/ogham/exa)
- (Optional) Install [`starship`](https://starship.rs)

### Local Config

OMF allows a custom local configuration file. Use this file for anything that needs to be local only to your current device, or to override some base configuration. Create folder: `mkdir -p $HOME/.local/fish`. Inside this folder you can place any file named `*.fish` for any custom local overrides.

In order for this to work, ensure that `$HOME/.config/omf` is pointing to your OMF config directory.

## Neovim

- Install `neovim`
- Run the included script to install `vim-plug`:
  - `./misc/scripts/install_vim-plug.fish`
- Install vim plugins: `nvim +PlugInstall`

## WM

Fonts in use:

- `feather` (aur/ttf-icomoon-feather)
- `Iosevka` (nerd)
- `FontAwesome` (nerd)

Download nerd fonts from [nerdfonts](https://www.nerdfonts.com/) (if you run Arch or a derivative, many of these are available in the community repository).

### i3

TBD

### bspwm

TBD

### polybar

TBD
