$env.DOTFILES_DIR = $"($env.HOME)/.dotfiles"
$env.NIXPKGS_ALLOW_UNFREE = 1

def is-os [os: string] {
  let os_lowercase = ($nu.os-info.name | str downcase)
  match $os {
    "linux" => ($os_lowercase == "linux"),
    "macos" => ($os_lowercase == "macos"),
    "darwin" => ($os_lowercase == "macos")
  }
}

def is-darwin [] {
  is-os "macos"
}

def is-macos [] {
  is-os "macos"
}

def is-linux [] {
  is-os "linux"
}

def "op get-ssh-key-id" [] {
  op item list --categories "SSH Key" --vault "Private" | lines | skip 1 | to text | fzf | split column -r '\s{2,}' ID TITLE VAULT EDITED | get ID | to text
}

def "sops get-age-key" [] {
  let private_key_id = (op get-ssh-key-id)
  nix-shell -p ssh-to-age --run $'op item get ($private_key_id) --fields "label=private key" --reveal | ssh-to-age -private-key'
}

def "sops write-age-key" [] {
  mkdir (dirname ~/.config/sops/age/keys.txt)
  sops get-age-key | save ~/.config/sops/age/keys.txt
}

use ./abbreviations.nu
let abbreviations = abbreviations get_abbreviations

source ./aliases.nu

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

