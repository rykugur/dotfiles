abbr --add --global nb "nix build"

alias ndl "nd --lua"
alias ndv "nd --nvim"
alias ndt "nd --tauri"

function nd --description "wrapper for my personal nix develop shell targets"
    argparse --name=nd l/lua n/nvim t/tauri -- $argv
    or return

    set -l _target default

    test -n "$_flag_l"; or test -n "$_flag_lua"; and set _target lua
    test -n "$_flag_n"; or test -n "$_flag_nvim"; and set _target nvim
    test -n "$_flag_t"; or test -n "$_flag_tauri"; and set _target tauri

    nix develop $HOME/.dotfiles\#$_target --command fish
end

complete -c nd -s lua -l lua -a lua
complete -c nd -s r -l react -a react
complete -c nd -s n -l nvim -a nvim

alias ndl "nd --lua"
alias ndn "nd --nvim"
alias ndr "nd --react"

abbr --add --global nf "nix flake"
abbr --add --global nfc "nix flake check"
abbr --add --global nfu "nix flake update"

abbr --add --global nr "nix repl"
abbr --add --global nrn "nix repl --file '<nixpkgs>'"
abbr --add --global nr. "nix repl --file ."
abbr --add --global nrf 'nix repl --expr "builtins.getFlake \"$HOME/.dotfiles\""'

abbr --add --global ns nix-shell

abbr --add --global snr "sudo nixos-rebuild"
abbr --add --global snrs "sudo nixos-rebuild switch"
abbr --add --global snrsf "sudo nixos-rebuild switch --flake $DOTFILES_DIR"

set -gx NIXPKGS_ALLOW_UNFREE 1

function shash
    nix hash to-sri --type sha256 (nix-prefetch-url $argv)
end
