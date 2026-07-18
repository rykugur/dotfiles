function op-ssh-public-key
    set -l item_id (__op-select-ssh-key $argv)
    or return
    op item get "$item_id" --fields 'label=public key'
end
