function sops-age-private-from-ssh
    nix run nixpkgs#ssh-to-age -- -private-key
end
