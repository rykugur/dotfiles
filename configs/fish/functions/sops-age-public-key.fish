function sops-age-public-key
    set -l item_id (__op-select-ssh-key $argv)
    or return
    op item get "$item_id" --fields 'label=public key' \
        | nix run nixpkgs#ssh-to-age
end
