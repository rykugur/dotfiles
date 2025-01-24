#TODO: turn this into a module!

use std log

def get-ssh-key-id [] {
  op item list --categories "SSH Key" --vault "Private" | lines | skip 1 | split column -r '\s+' ID TITLE VAULT | input list --fuzzy 'Select SSH Key' | get ID
}

def get-public-key [sshKeyId: string] {
  op item get $sshKeyId --fields "label=public key"
}

def get-private-key [sshKeyId: string] {
  op item get $sshKeyId --fields "label=private key" --reveal
}

# def get-private-age-key [privateKey: string --write (-w)] {
#   # nix-shell -p ssh-to-age --run $"echo ($privateKey) | ssh-to-age -private-key"
#   let key = $privateKey | nix run nixpkgs#ssh-to-age -- -private-key
#
#   if ($write) {
#     mkdir ~/.config/sops/age
#     $key | save ~/.config/sops/age/keys.txt
#   } else {
#     return key
#   }
# }

# def write-private-age-key2 [privateKey: string path: string = "~/.config/sops/age2/keys.txt"] {
#   if (($path | path exists) == false) {
#     mkdir ($path | path dirname)
#   }
#   $privateKey | nix run nixpkgs#ssh-to-age -- -private-key | save $path
# }

def write-private-age-key [--path: string] {
  if ($in | is-empty) {
    log error "No key provided"
    return
  }

  let path = if ($path | is-not-empty) { $path } else { $"($env.HOME)/.config/sops/age/keys.txt" }
  log info $"path=($path)"

  # mkdir -v ($path | path dirname)

  let dirname = $path | path dirname
  if (($dirname | path exists) == false) {
    log info $"path=($dirname) didn't exist, creating..."
    # mkdir -v $dirname
  }

  # $in | nix run nixpkgs#ssh-to-age -- -private-key | save $path
}

def get-private-age-key [] {
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

def get-public-age-key [] {
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

def setup-host [hostName: string] {
  let sshKeyId = get-ssh-key-id
  if ($sshKeyId | is-empty) {
    log error "No SSH key found or selected"
    return
  }

  # let publicKey = get-public-key $sshKeyId

  let publicAgeKey = $sshKeyId | get-public-age-key
  let privateAgeKey = $sshKeyId | get-private-age-key
}

# def main [] {
#   let sshKeyId = get-ssh-key-id
#
#   let publicKey = get-public-key $sshKeyId
#   log debug $"publicKey=($publicKey)"
#
#   let privateKey = get-private-key $sshKeyId
#   log debug $"privateKey=($privateKey)"
#
#   let publicAgeKey = get-public-age-key $publicKey
#   log debug $"publicAgeKey=($publicAgeKey)"
#
#   let privateAgeKey = get-private-age-key $privateKey
#   log debug $"privateAgeKey=($privateAgeKey)"
# }
