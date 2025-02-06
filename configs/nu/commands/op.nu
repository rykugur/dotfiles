use ../modules/1password

def "op get-public-key" [] {
  let sshKeyId = 1password get-ssh-key-id
  if ($sshKeyId | is-empty) {
    log error "No SSH key found or selected"
    return
  }
  1password get-public-key $sshKeyId
}

def "op get-private-key" [] {
  let sshKeyId = 1password get-ssh-key-id
  if ($sshKeyId | is-empty) {
    log error "No SSH key found or selected"
    return
  }
  1password get-private-key $sshKeyId
}
