source ./aliases.nu
source ./commands/commands.nu
source ./zellij.nu

# TODO: autoload or add to NU_LIB_DIRS?
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
