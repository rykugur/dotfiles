use 1password [get-ssh-key-id get-private-key get-public-key]
use std/log

export def get-private-age-key [] {
  let sshKeyId = if ($in | is-not-empty) { $in } else { get-ssh-key-id }
  if ($sshKeyId | is-empty) {
    log error "No SSH key found or selected"
    return
  }

  let privateKey = $sshKeyId | get-private-key
  if ($privateKey | is-empty) {
    log error "No private key found"
    return
  }

  $privateKey | nix run nixpkgs#ssh-to-age -- -private-key
}

export def get-private-age-key-from-private-ssh-key [] {
  if ($in | is-empty) {
    log error "No private key provided. Usage: 'someKey' | get-private-age-key-from-private-ssh-key"
  }

  let privateKey = $in
  $privateKey | nix run nixpkgs#ssh-to-age -- -private-key
}

export def get-public-age-key [] {
  let sshKeyId = if ($in | is-not-empty) { $in } else { get-ssh-key-id }
  if ($sshKeyId | is-empty) {
    log error "No SSH key found or selected"
    return
  }

  let publicKey = $sshKeyId | get-public-key
  if ($publicKey | is-empty) {
    log error "No public key found"
    return
  }

  $publicKey | nix run nixpkgs#ssh-to-age
}

export def setup-new-host [--yes (-y)] {
  let sshKeyId = get-ssh-key-id
  if ($sshKeyId | is-empty) {
    log error "No SSH key found or selected"
    return
  }

  let publicAgeKey = $sshKeyId | get-public-age-key
  log info $"publicAgeKey=($publicAgeKey)"
  let privateAgeKey = $sshKeyId | get-private-age-key
  log debug $"privateAgeKey=($privateAgeKey)"

  let keysTxtPath = "~/.config/sops/age/keys.txt"

  let yes = if (not $yes) {
    let response = (input $"Write private age key to ($keysTxtPath)? \(y/N\): ")
    $response == "y" or $response == "Y"
  } else {
    true
  }

  if ($yes) {
    log info $"Writing keys.txt file to ($keysTxtPath)"
    mkdir -v ~/.config/sops/age
    $privateAgeKey | save $keysTxtPath
  } else {
    log info "Skipped writing keys.txt file"
  }
}
