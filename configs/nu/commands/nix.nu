def rbld [--boot (-b)] {
  if (is-darwin) {
    # have to cd first, doesn't seem to like symlinks (which dotfiles may or may not be)
    cd $env.DOTFILES_DIR; darwin-rebuild switch --flake .
  } else if (is-linux) {
    sudo nixos-rebuild (if $boot {"boot"} else {"switch"}) --flake $env.DOTFILES_DIR
  }
}

def "nix get-hash" [url: string] {
  nix hash convert --hash-algo sha256 (nix-prefetch-url $url)
}

def "shash" [url: string] {
  nix hash convert --hash-algo sha256 (nix-prefetch-url $url)
}

def nrf [--remote (-r)] {
  let url = if ($remote) {
    "github:rykugur/dotfiles"
  } else {
    $"($env.HOME)/.dotfiles"
  }

  nix repl --expr $"builtins.getFlake \"($url)\""
}
