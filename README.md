# dotfiles

This is a very poorly named repo, as it now contains more than just dotfiles. Eventually I'll update this README. Maybe. Possibly.

# Installation

- First run `git submodule update --init --remote --recursive` to initialize the rofi/polybar submodules

## Terminal

- Install [fish shell](https://fishshell.com/) (should be in your distro's repositories).
- Ensure fish exists on your path: `which -a fish`
  - If on a mac, and using homebrew, add brew to your path: `PATH=/opt/homebrew/bin:$PATH`
- Set fish as your default shell: `chsh -s $(which -a fish)`
  - This is optional, fish can be manually started from a bash shell.
  - If this doesn't work, `chsh -s /path/to/fish` (note that sometimes you'll need to add `/path/to/fish` to `/etc/shells`).
    - Again `which -a fish` will list any `fish` executables on your `PATH`.
  - You need to log out and back in for this to take effect.
- Install [`oh-my-fish`](https://github.com/oh-my-fish/oh-my-fish)
- Create symlink to omf config: `ln -s [dotfiles]/configs/fish/omf $HOME/.config/omf`
- (Optional) Install [`exa`](https://github.com/ogham/exa)
- (Optional) Install [`starship`](https://starship.rs)

### Local Config

OMF allows a custom local configuration file. Use this file for anything that needs to be local only to your current device, or to override some base configuration. Create folder: `mkdir -p $HOME/.local/fish`. Inside this folder you can place any file named `*.fish` for any custom local overrides.

In order for this to work, ensure that `$HOME/.config/omf` is pointing to your OMF config directory.

Note that the sourcing of local config files happens last in the initialization chain; this is done to allow overriding of default values.

## Neovim

- Install `neovim`
- Symlink to LazyVim config: `mv $HOME/.config/nvim $HOME/.config/nvim.bak; ln -s [dotfiles]/configs/nvim/lazyvim $HOME/.config/nvim`

NOTE: use [`neovide`](https://neovide.dev/) for slick animations.

You may define in `~/.local/fish/config.fish` (or elsewhere) a variable called `LOCAL_NVIM_DIRS`, this should be a comma-delimited string of directories that will show as options to open as the working dir in `nvim`.

## WM

Fonts in use:

- `feather` (aur/ttf-icomoon-feather)
- `Iosevka` (nerd)
- `FontAwesome` (nerd)

Download nerd fonts from [nerdfonts](https://www.nerdfonts.com/) (if you run Arch or a derivative, many of these are available in the community repository).

### i3

Create a symlink in your `$HOME/.config` to the i3 dir: `ln -s [dotfiles]/configs/i3 $HOME/.config/i3`.

### polybar

Polybar themes are handled via a personal fork of the [amazing polybar-themes repo from adi1090x](https://github.com/adi1090x/polybar-themes). Just make sure the submodule is initialized (see [Installation](#installation)).

There is no need to run the included `setup.sh` script unless you want it installed locally (will default to `~/.config`).

### rofi

Rofi themes are handled via a personal fork of the [amazing rofi(-themes) repo from adi1090x](https://github.com/adi1090x/rofi). Just make sure the submodule is initialized (see [Installation](#installation)).

There is no need to run the included `setup.sh` script unless you want it installed locally (will default to `~/.config`).

### picom

TBD
