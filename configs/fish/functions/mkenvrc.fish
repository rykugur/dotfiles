function mkenvrc
    printf '%s\n' "if nix registry list 2>/dev/null | grep -q '^system.*nixpkgs'; then" '    use flake . --override-input nixpkgs flake:nixpkgs' 'else' '    use flake .' 'fi' > .envrc
end
