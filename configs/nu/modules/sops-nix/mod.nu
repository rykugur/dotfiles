use ../op

export def get-private-age-key [] {
  let sshKeyId = if ($in | is-not-empty) { $in } else { op get-ssh-key-id }
  if ($sshKeyId | is-empty) {
    log error "No SSH key found or selected"
    return
  }

  let privateKey = op get-private-key $sshKeyId
  if ($privateKey | is-empty) {
    log error "No private key found"
    return
  }

  $privateKey | nix run nixpkgs#ssh-to-age -- -private-key
}

export def get-public-age-key [] {
  let sshKeyId = if ($in | is-not-empty) { $in } else { op get-ssh-key-id }
  if ($sshKeyId | is-empty) {
    log error "No SSH key found or selected"
    return
  }

  let publicKey = op get-public-key $sshKeyId
  if ($publicKey | is-empty) {
    log error "No public key found"
    return
  }

  $publicKey | nix run nixpkgs#ssh-to-age
}
