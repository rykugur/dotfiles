source ./aliases/index.nu
source ./commands/index.nu
source ./zellij.nu

use ./abbreviations/abbreviations.nu
$env.config.keybindings = $env.config.keybindings | append (abbreviations get_keybinds)
$env.config.menus = $env.config.menus | append (abbreviations get_menus)

$env.HELM_CONFIG_HOME = $"($env.HOME)/.config/helm"

# $env.config.edit_mode = 'vi'
$env.config.keybindings ++= [
  {
    name: hint_completion
    modifier: control
    keycode: char_f
    mode: [emacs vi_insert vi_normal]
    event: {send: HistoryHintComplete}
  }
]
