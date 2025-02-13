$env.DOTFILES_DIR = $"($env.HOME)/.dotfiles"
$env.NIXPKGS_ALLOW_UNFREE = 1
$env.EDITOR = "hx"
$env.STEAM_LIBRARY_DIR = "~/.local/share/steam"
$env.NU_LOG_LEVEL = "DEBUG"

$env.NU_LIB_DIRS = [
  $"($env.DOTFILES_DIR)/configs/nu/modules"
]
