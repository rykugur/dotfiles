$env.abbreviations = {}

source ./git.nu
source ./k8s.nu
source ./git.nu
source ./linux.nu
source ./misc.nu
source ./nix.nu
source ./pz.nu
source ./zellij.nu

source ./eve.nu
source ./starcitizen.nu

use ./abbreviations.nu
$env.config.keybindings = $env.config.keybindings | append (abbreviations get_keybinds)
$env.config.menus = $env.config.menus | append (abbreviations get_menus)

hide-env abbreviations

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
