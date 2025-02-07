export def get-ssh-key-id [] {
  ^op item list --categories "SSH Key" | lines | skip 1 | split column -r '\s{2,}' ID TITLE VAULT | input list --fuzzy 'Select SSH Key' | get ID
}

export def get-public-key [] {
  let sshKeyId = if ($in | is-not-empty) { $in } else { get-ssh-key-id }
  if ($sshKeyId | is-empty) {
    log error "No SSH key found or selected"
    return
  }
  ^op item get $sshKeyId --fields "label=public key"
}

export def get-private-key [] {
  let sshKeyId = if ($in | is-not-empty) { $in } else { get-ssh-key-id }
  if ($sshKeyId | is-empty) {
    log error "No SSH key found or selected"
    return
  }
  ^op item get $sshKeyId --fields "label=private key" --reveal
}
