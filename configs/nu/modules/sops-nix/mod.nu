export def get-ssh-key-id [] {
  op item list --categories "SSH Key" --vault "Private" | lines | skip 1 | split column -r '\s+' ID TITLE VAULT | input list --fuzzy 'Select SSH Key' | get ID
}

export def get-public-key [sshKeyId: string] {
  op item get $sshKeyId --fields "label=public key"
}

export def get-private-key [sshKeyId: string] {
  op item get $sshKeyId --fields "label=private key" --reveal
}

export def get-private-age-key [] {
  let sshKeyId = if ($in | is-not-empty) { $in } else { get-ssh-key-id }
  if ($sshKeyId | is-empty) {
    log error "No SSH key found or selected"
    return
  }

  let privateKey = get-private-key $sshKeyId
  if ($privateKey | is-empty) {
    log error "No private key found"
    return
  }

  $privateKey | nix run nixpkgs#ssh-to-age -- -private-key
}

export def get-public-age-key [] {
  let sshKeyId = if ($in | is-not-empty) { $in } else { get-ssh-key-id }
  if ($sshKeyId | is-empty) {
    log error "No SSH key found or selected"
    return
  }

  let publicKey = get-public-key $sshKeyId
  if ($publicKey | is-empty) {
    log error "No public key found"
    return
  }

  $publicKey | nix run nixpkgs#ssh-to-age
}
