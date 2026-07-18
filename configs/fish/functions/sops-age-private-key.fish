function sops-age-private-key
    set -l item_id (__op-select-ssh-key $argv)
    or return
    op item get "$item_id" --fields 'label=private key' --reveal \
        | nix run nixpkgs#ssh-to-age -- -private-key
end
