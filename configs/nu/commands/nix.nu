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
