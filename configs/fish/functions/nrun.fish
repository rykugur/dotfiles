function nrun
    test (count $argv) -eq 1; or return 2
    nix run "nixpkgs#$argv[1]"
end
