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
    sudo darwin-rebuild switch --flake $env.DOTFILES_DIR e+o>| nom
  } else if (is-linux) {
    sudo nixos-rebuild switch --flake $env.DOTFILES_DIR e+o>| nom
  }
}

def "rbld boot" [] {
  if (is-darwin) {
    log error "darwin-rebuild doesn't support boot flag, ignoring"
  } else if (is-linux) {
    sudo nixos-rebuild boot --flake $env.DOTFILES_DIR e+o>| nom
  }
}

def nd [] {
  const targets = ["lua", "kubes"]
  let selection = ($targets | str join "\n" | fzf)
  if ($selection | is-not-empty) {
    nix develop $"($env.DOTFILES_DIR)#($selection)" -c $env.SHELL
  } else {
    log info "No target selected."
  }
}

def "nix get-hash" [url: string] {
  nix hash convert --hash-algo sha256 (nix-prefetch-url $url)
}

def "shash" [url: string] {
  nix hash convert --hash-algo sha256 (nix-prefetch-url $url)
}

def "nr." [] {
  nix repl --expr $"builtins.getFlake \"(pwd)\""
}

def "nrd" [] {
  nix repl --expr $"builtins.getFlake \"($env.DOTFILES_DIR)\""
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
