abbr --add --global nb "nix build"
abbr --add --global nd "nix develop ~/.dotfiles#default --command fish"
abbr --add --global ndr "nix develop ~/.dotfiles#react --command fish"
abbr --add --global nr "nix repl"
abbr --add --global nrn "nix repl --file '<nixpkgs>'"
abbr --add --global nr. "nix repl --file ."
abbr --add --global nrf 'nix repl --expr "builtins.getFlake \"$HOME/.dotfiles\""'

abbr --add --global nixdev nix develop $DOTFILES_DIR --command fish

abbr --add --global snr "sudo nixos-rebuild"
abbr --add --global snrs "sudo nixos-rebuild switch"
abbr --add --global snrsf "sudo nixos-rebuild switch --flake $DOTFILES_DIR"

abbr --add --global hm home-manager
abbr --add --global hms "home-manager switch"
abbr --add --global hmsf "home-manager switch --flake $DOTFILES_DIR"

alias chrome "NIXPKGS_ALLOW_UNFREE=1 nix-shell -p google-chrome --run google-chrome-stable"

function shash
    nix hash to-sri --type sha256 (nix-prefetch-url $argv)
end
