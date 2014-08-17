# Path to your oh-my-fish.
set fish_path $HOME/.oh-my-fish

# Theme
set fish_theme rollhax

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-fish/plugins/*)
# Custom plugins may be added to ~/.oh-my-fish/custom/plugins/
# Example format: set fish_plugins autojump bundler
set fish_plugins sublime

# Path to your custom folder (default path is $FISH/custom)
#set fish_custom $HOME/dotfiles/oh-my-fish

# Load oh-my-fish configuration.
. $fish_path/oh-my-fish.fish

# custom config.fish stuff below:
#
# don't greet me!
set fish_greeting ""

# exports
set -x PATH $PATH ~/bin
#set -x WINEPREFIX "/home/dusty/.PlayOnLinux/wineprefix/.wine32_cmst"
set -x WINEPREFIX "/home/dusty/.wine32"
set -x WINEARCH "win32"

# "aliases" and quickie functions
alias arches "ssh arches"

function steamcd 
  cd ~/.local/share/Steam/SteamApps/common
end

function nvsettings
  primusrun nvidia-settings -c :8 &
end

function steam_wine
  primusrun "/home/dusty/.wine32/drive_c/Program Files/Steam/Steam.exe"
end

function pacman_deps
  pacman -Qi | sed '/^Depends On/,/^Required By/{ s/^Required By.*$//; H; d }; /^Name/!d; /^Name/{ n;x;}'| sed '/^$/s//==================================================================================/'
end

function update_pacman_mirrors
  sudo reflector --verbose --country 'United States' -l 200 -p http --sort rate --save /etc/pacman.d/mirrorlist
end
