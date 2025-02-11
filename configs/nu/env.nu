$env.DOTFILES_DIR = $"($env.HOME)/.dotfiles"
$env.NIXPKGS_ALLOW_UNFREE = 1
$env.EDITOR = "nvim"
$env.STEAM_LIBRARY_DIR = "~/.local/share/steam"
$env.NU_LOG_LEVEL = "DEBUG"

# TODO: why does this break in zellij?
#$env.PATH = $env.PATH | append $"($env.HOME)/bin"
$env.PATH = $"($env.PATH):($env.HOME)/bin"

$env.NU_LIB_DIRS = [
  $"($env.DOTFILES_DIR)/configs/nu/modules"
]
