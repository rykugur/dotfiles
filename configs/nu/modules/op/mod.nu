export def get-ssh-key-id [] {
  op item list --categories "SSH Key" | lines | skip 1 | split column -r '\s{2,}' ID TITLE VAULT | input list --fuzzy 'Select SSH Key' | get ID
}

export def get-public-key [sshKeyId: string] {
  op item get $sshKeyId --fields "label=public key"
}

export def get-private-key [sshKeyId: string] {
  op item get $sshKeyId --fields "label=private key" --reveal
}

