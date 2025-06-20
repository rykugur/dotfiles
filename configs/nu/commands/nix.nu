use std/log

def rbld [--boot (-b)] {
  rbld switch
}

def "rbld switch" [] {
  if (is-darwin) {
    # have to cd first, doesn't seem to like symlinks (which dotfiles may or may not be)
    cd $env.DOTFILES_DIR; sudo darwin-rebuild switch --flake . e+o>| nom
  } else if (is-linux) {
    sudo nixos-rebuild switch --flake $env.DOTFILES_DIR e+o>| nom
  }
}

def "rbld boot" [] {
  if (is-darwin) {
    # have to cd first, doesn't seem to like symlinks (which dotfiles may or may not be)
    cd $env.DOTFILES_DIR; sudo darwin-rebuild boot --flake . e+o>| nom
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

def nrf [--remote (-r)] {
  let url = if ($remote) {
    "github:rykugur/dotfiles"
  } else {
    $"($env.HOME)/.dotfiles"
  }

  nix repl --expr $"builtins.getFlake \"($url)\""
}
