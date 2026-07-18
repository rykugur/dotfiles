function nix-get-hash
    test (count $argv) -eq 2; or return 2
    nix-prefetch-git --url $argv[1] --rev $argv[2]
end
