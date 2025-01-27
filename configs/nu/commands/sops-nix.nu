use std log
use ../modules/sops-nix

def sops-new-host [--yes (-y)] {
  let sshKeyId = sops-nix get-ssh-key-id
  if ($sshKeyId | is-empty) {
    log error "No SSH key found or selected"
    return
  }

  let publicAgeKey = $sshKeyId | sops-nix get-public-age-key
  log info $"publicAgeKey=($publicAgeKey)"
  let privateAgeKey = $sshKeyId | sops-nix get-private-age-key
  log debug $"privateAgeKey=($privateAgeKey)"

  let keysTxtPath = "~/.config/sops/age/keys.txt"

  let yes = if (not $yes) {
    let response = (input $"Write private age key to ($keysTxtPath)? \(y/N\): ")
    $response == "y" or $response == "Y"
  } else {
    true
  }

  if ($yes) {
    log info $"writing keys.txt file to ($keysTxtPath)"
    mkdir -v ~/.config/sops/age
    $privateAgeKey | save $keysTxtPath
  }
}

def get-private-age-key [] {
  sops-nix get-private-age-key
}
