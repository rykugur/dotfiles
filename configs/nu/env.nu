$env.GITS_DIR = $"($env.HOME)/gits"
$env.DOTFILES_DIR = $"($env.HOME)/.dotfiles"

$env.EDITOR = "hx"
$env.NIXPKGS_ALLOW_UNFREE = 1
$env.STEAM_LIBRARY_DIR = "~/.local/share/steam"

$env.NH_FLAKE = $env.DOTFILES_DIR

$env.NU_LOG_LEVEL = "DEBUG"
$env.NU_LIB_DIRS = [
  $"($env.DOTFILES_DIR)/configs/nu/modules"
]
