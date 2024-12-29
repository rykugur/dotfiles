$env.DOTFILES_DIR = $"($env.HOME)/.dotfiles"
$env.NIXPKGS_ALLOW_UNFREE = 1
$env.EDITOR = "nvim"
$env.STEAM_LIBRARY_DIR = "~/.local/share/steam"
$env.PATH = ($env.PATH | append $"($env.HOME)/bin")

use ./abbreviations.nu
let abbreviations = abbreviations get_abbreviations

source ./aliases.nu

source ./commands.nu

source ./hooks/fnm.nu

$env.config = {
  keybindings: [
    {
      name: abbr_menu
      modifier: none
      keycode: enter
      mode: [emacs, vi_normal, vi_insert]
      event: [
        { send: menu name: abbr_menu }
        { send: enter }
      ]
    }
    {
      name: abbr_menu
      modifier: none
      keycode: space
      mode: [emacs, vi_normal, vi_insert]
      event: [
        { send: menu name: abbr_menu }
        { edit: insertchar value: ' '}
      ]
    }
  ]

  menus: [
    {
      name: abbr_menu
      only_buffer_difference: false
      marker: none
      type: {
        layout: columnar
        columns: 1
        col_width: 20
        col_padding: 2
      }
      style: {
        text: green
        selected_text: green_reverse
        description_text: yellow
      }
      source: { |buffer, position|
        let match = $abbreviations | columns | where $it == $buffer
        if ($match | is-empty) {
            { value: $buffer }
        } else {
            { value: ($abbreviations | get $match.0) }
        }
      }
    }
  ]
}

# finally, clean up PATH
$env.PATH = $env.PATH | uniq
