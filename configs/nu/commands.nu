export def is-os [os: string] {
  let os_lowercase = ($nu.os-info.name | str downcase)
  match $os {
    "linux" => ($os_lowercase == "linux"),
    "macos" => ($os_lowercase == "macos"),
    "darwin" => ($os_lowercase == "macos")
  }
}

export def is-darwin [] {
  is-os "macos"
}

export def is-macos [] {
  is-os "macos"
}

export def is-linux [] {
  is-os "linux"
}

export def rbld [] {
  if (is-darwin) {
    darwin-rebuild switch --flake $env.DOTFILES_DIR
  } else if (is-linux) {
    sudo nixos-rebuild switch --flake $env.DOTFILES_DIR
  }
}

export def "op get-ssh-key-id" [] {
  op item list --categories "SSH Key" --vault "Private" | lines | skip 1 | to text | fzf | split column -r '\s{2,}' ID TITLE VAULT EDITED | get ID | to text
}

export def "sops get-age-key" [] {
  let private_key_id = (op get-ssh-key-id)
  nix-shell -p ssh-to-age --run $'op item get ($private_key_id) --fields "label=private key" --reveal | ssh-to-age -private-key'
}

export def "sops write-age-key" [] {
  mkdir (dirname ~/.config/sops/age/keys.txt)
  sops get-age-key | save ~/.config/sops/age/keys.txt
}

export def "nix get-hash" [url: string] {
  nix hash to-sri --type sha256 (nix-prefetch-url $url)
}
