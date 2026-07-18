abbr --add --global nb "nix build"
abbr --add --global ndb nix-build

function nd --description "Enter a dotfiles Nix development shell"
    test (count $argv) -eq 1; or return 2
    nix develop "$DOTFILES_DIR#$argv[1]"
end

abbr --add --global nf "nix flake"
abbr --add --global nfc "nix flake check"
abbr --add --global nfu "nix flake update"

abbr --add --global nr "nix repl"
abbr --add --global nrn "nix repl --file '<nixpkgs>'"
function nr. --description "Open a Nix REPL for the current directory"
    nix repl --expr "builtins.getFlake \"$PWD\""
end

abbr --add --global ns 'nix shell'
abbr --add --global nds nix-shell
abbr --add --global ndsp 'nix-shell -p'

abbr --add --global snr "sudo nixos-rebuild"
abbr --add --global snrs "sudo nixos-rebuild switch"
abbr --add --global snrsf "sudo nixos-rebuild switch --flake $DOTFILES_DIR"
abbr --add --global snrb 'sudo nixos-rebuild boot'
abbr --add --global snrbf 'sudo nixos-rebuild boot --flake $DOTFILES_DIR'
abbr --add --global snrbfu 'sudo nixos-rebuild boot --flake $DOTFILES_DIR --update'
abbr --add --global snb 'sudo nixos-rebuild boot'
abbr --add --global snrsfu 'sudo nixos-rebuild switch --flake $DOTFILES_DIR --update'

function shash
    test (count $argv) -eq 2; or return 2
    nix-prefetch-git --url "$argv[1]" --rev "$argv[2]"
end
