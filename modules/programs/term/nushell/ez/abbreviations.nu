let abbreviations = {
  nb : "nix build"
  nf : "nix flake"
  nfc : "nix flake check"
  nfu : "nix flake update"
  nr : "nix repl"
  nrn : "nix repl --file '<nixpkgs>'"
  "nr." : "nix repl --file ."
  nrf : "nix repl --expr \"builtins.getFlake $env.HOME/.dotfiles\""
  ns : "nix shell"
  snr : "sudo nixos-rebuild"
  snrs : "sudo nixos-rebuild switch"
  snrsf : "sudo nixos-rebuild switch --flake $env.HOME/.dotfiles"
  shash : "nix hash to-sri --type sha256 (nix-prefetch-url $argv)"

  nds : "nix-shell"
}
