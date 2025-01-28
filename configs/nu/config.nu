$env.DOTFILES_DIR = $"($env.HOME)/.dotfiles"
$env.NIXPKGS_ALLOW_UNFREE = 1
$env.EDITOR = "nvim"
$env.STEAM_LIBRARY_DIR = "~/.local/share/steam"
$env.PATH = $env.PATH | append $"($env.HOME)/bin"

source ./aliases.nu

source ./hooks/fnm.nu

source ./completions/bun.nu
source ./completions/yarn-classic.nu

source ./zellij.nu

source ./commands/commands.nu

use ./abbreviations.nu
$env.config.keybindings = $env.config.keybindings | append (abbreviations get_keybinds)
$env.config.menus = $env.config.menus | append (abbreviations get_menus)

# finally, clean up PATH
$env.PATH = $env.PATH | uniq
