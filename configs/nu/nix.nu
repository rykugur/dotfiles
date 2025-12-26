use std/log

def rbld [--boot (-b)] {
  if ($boot) {
    rbld boot
  } else {
    rbld switch
  }
}

def "rbld switch" [] {
  if (is-darwin) {
    nh darwin switch $env.DOTFILES_DIR
  } else if (is-linux) {
    nh os switch $env.DOTFILES_DIR
  }
}

def "rbld boot" [] {
  if (is-darwin) {
    log error "darwin-rebuild doesn't support boot flag, ignoring"
  } else if (is-linux) {
    nh os boot $env.DOTFILES_DIR
  }
}

def nd [shell: string] {
  nix develop $"($env.DOTFILES_DIR)#($shell)"
}

def "nix get-hash" [url: string rev: string] {
  nix-prefetch-git --url $url --rev $rev
}

def "shash" [url: string rev: string] {
  nix get-hash $url $rev
}

def "nr." [] {
  nix repl --expr $"builtins.getFlake \"(pwd)\""
}

def "nrd" [] {
  cd $env.DOTFILES_DIR
  nr.
}

def "nrn" [] {
  nix repl --file '<nixpkgs>'
}

def nrf [--remote (-r)] {
  let url = if ($remote) {
    "github:rykugur/dotfiles"
  } else {
    $"($env.HOME)/.dotfiles"
  }

  nix repl --expr $"builtins.getFlake \"($url)\""
}

def nrun [pkg: string] {
  nix run $"nixpkgs#($pkg)"
}

$env.abbreviations = $env.abbreviations | merge {
  nb: "nix build"
  ndb: "nix-build"

  nf: "nix flake"
  nfc: "nix flake check"
  nfu: "nix flake update"

  ns: "nix shell"
  nds: "nix-shell"
  ndsp: "nix-shell -p"

  snrb: "sudo nixos-rebuild boot"
  snrbf: "sudo nixos-rebuild boot --flake $env.DOTFILES_DIR"
  snrbfu: "sudo nixos-rebuild boot --flake $env.DOTFILES_DIR --update"
  snb: "sudo nixos-rebuild boot"
  snr: "sudo nixos-rebuild"
  snrs: "sudo nixos-rebuild switch"
  snrsf: "sudo nixos-rebuild switch --flake $env.DOTFILES_DIR"
  snrsfu: "sudo nixos-rebuild switch --flake $env.DOTFILES_DIR --update"
}
