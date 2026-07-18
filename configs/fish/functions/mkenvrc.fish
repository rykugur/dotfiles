function mkenvrc
    if test -e .envrc -o -L .envrc
        echo '.envrc already exists; refusing to overwrite it' >&2
        return 1
    end
    printf '%s\n' "if nix registry list 2>/dev/null | grep -q '^system.*nixpkgs'; then" '    use flake . --override-input nixpkgs flake:nixpkgs' 'else' '    use flake .' 'fi' > .envrc
end
