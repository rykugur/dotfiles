$env.DOTFILES_DIR = $"($env.HOME)/.dotfiles"
$env.NIXPKGS_ALLOW_UNFREE = 1
$env.EDITOR = "hx"
$env.STEAM_LIBRARY_DIR = "~/.local/share/steam"
$env.NU_LOG_LEVEL = "DEBUG"

$env.EVE_SETTINGS_DIR = $"($env.HOME)/.local/share/Steam/steamapps/compatdata/8500/pfx/drive_c/users/steamuser/AppData/Local/CCP/EVE/c_ccp_eve_tq_tranquility"

$env.NU_LIB_DIRS = [
  $"($env.DOTFILES_DIR)/configs/nu/modules"
]
