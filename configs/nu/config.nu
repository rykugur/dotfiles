source ./aliases.nu
source ./commands/commands.nu
source ./zellij.nu

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
