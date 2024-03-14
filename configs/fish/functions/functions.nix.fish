function shash
    nix hash to-sri --type sha256 (nix-prefetch-url $argv)
end
