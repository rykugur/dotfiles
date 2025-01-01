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

def "cmd.copy" [] {
  if (is-linux) {
    $in | wl-copy
  } else if (is-darwin) {
    $in | pbcopy
  }
}

def "cmd.paste" [] {
  if (is-linux) {
    wl-paste
  } else if (is-darwin) {
    pbpaste
  }
}

def rbld [] {
  if (is-darwin) {
    # have to cd first, doesn't seem to like symlinks (which dotfiles may or may not be)
    cd $env.DOTFILES_DIR; darwin-rebuild switch --flake .
  } else if (is-linux) {
    sudo nixos-rebuild switch --flake $env.DOTFILES_DIR
  }
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

def "nix get-hash" [url: string] {
  nix hash convert --hash-algo sha256 (nix-prefetch-url $url)
}

def "shash" [url: string] {
  nix hash convert --hash-algo sha256 (nix-prefetch-url $url)
}
