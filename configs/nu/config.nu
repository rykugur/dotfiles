$env.DOTFILES_DIR = $"($env.HOME)/.dotfiles"
$env.NIXPKGS_ALLOW_UNFREE = 1
$env.EDITOR = "nvim"
$env.STEAM_LIBRARY_DIR = "~/.local/share/steam"
$env.PATH = $env.PATH | append $"($env.HOME)/bin"

source ./aliases.nu
source ./commands/commands.nu
source ./zellij.nu

use ./modules/1password
use ./modules/sops-nix

source ./completions/bun.nu
source ./completions/yarn-classic.nu

use ./abbreviations.nu
$env.config.keybindings = $env.config.keybindings | append (abbreviations get_keybinds)
$env.config.menus = $env.config.menus | append (abbreviations get_menus)

$env.config.edit_mode = 'vi'
$env.config.keybindings ++= [
  {
    name: hint_completion
    modifier: control
    keycode: char_f
    mode: [emacs vi_insert vi_normal]
    event: {send: HistoryHintComplete}
  }
]

# finally, clean up PATH
$env.PATH = $env.PATH | uniq
