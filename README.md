# dotfiles

This is a very poorly named repo, as it now contains more than just dotfiles. Eventually I'll update this README. Maybe. Possibly.

# Installation

## Terminal

- Install [fish shell](https://fishshell.com/) (should be in your distro's repositories).
- Ensure fish exists on your path: `which -a fish`
  - If on a mac, and using homebrew, add brew to your path: `PATH=/opt/homebrew/bin:$PATH`
- Set fish as your default shell: `chsh -s $(which -a fish)`
  - This is optional, fish can be manually started from a bash shell.
  - If this doesn't work, `chsh -s /path/to/fish` (note that sometimes you'll need to add `/path/to/fish` to `/etc/shells`).
    - Again `which -a fish` will list any `fish` executables on your `PATH`.
- Create symlink to omf config: `ln -s [dotfiles]/configs/fish/omf $HOME/.config/omf`
- Install OMF: `./misc/scripts/install_omf.fish`
- (Optional) Install [`exa`](https://github.com/ogham/exa)
- (Optional) Install [`starship`](https://starship.rs)

### Local Config

OMF allows a custom local configuration file. Use this file for anything that needs to be local only to your current device, or to override some base configuration. Create folder: `mkdir -p $HOME/.local/fish`. Inside this folder you can place any file named `*.fish` for any custom local overrides.

In order for this to work, ensure that `$HOME/.config/omf` is pointing to your OMF config directory.

## Neovim

- Install `neovim`
- Install [`nvhad`](https://nvchad.com/).
  - `git clone https://github.com/NvChad/NvChad ~/.config/nvim --depth 1 && nvim`
- Update symlinks: `rm -rf $HOME/.config/nvim/custom; ln -s [dotfiles]/configs/nvim/nvchad/custom $HOME/.config/nvim/lua/custom`

NOTE: use [`neovide`](https://neovide.dev/) for slick animations.

## WM

Fonts in use:

- `feather` (aur/ttf-icomoon-feather)
- `Iosevka` (nerd)
- `FontAwesome` (nerd)

Download nerd fonts from [nerdfonts](https://www.nerdfonts.com/) (if you run Arch or a derivative, many of these are available in the community repository).

### i3

Create a symlink in your `$HOME/.config` to the i3 dir: `ln -s [dotfiles]/configs/i3 $HOME/.config/i3`.

### bspwm

TBD

### polybar

Clone the [adi1090x/polybar-themes](https://github.com/adi1090x/polybar-themes) repo and run the install script (it will attempt to backup your existing polybar config). Bar startup is handled in [startup.conf](configs/polybar/launch.fish) (just change the path to use a different bar).

Any module customization should be done in your `~/.config/polybar` directory.

### rofi

Clone the [rofi(-themes)](https://github.com/adi1090x/rofi) repo and run the install script (it should again backup your existing configs). Binds handled in [binds.conf](configs/i3/binds.conf).

### picom

Makes use of the pijulius' fork of picom; install `picom-pijulius-git` (or your distro's analog).
