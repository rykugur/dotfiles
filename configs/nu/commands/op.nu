use ../modules/op

def "1password get-public-key" [] {
  let sshKeyId = op get-ssh-key-id
  if ($sshKeyId | is-empty) {
    log error "No SSH key found or selected"
    return
  }
  op get-public-key $sshKeyId
}

def "1password get-private-key" [] {
  let sshKeyId = op get-ssh-key-id
  if ($sshKeyId | is-empty) {
    log error "No SSH key found or selected"
    return
  }
  op get-private-key $sshKeyId
}

def "1password get-ssh-key-id" [] {
  op get-ssh-key-id
}
