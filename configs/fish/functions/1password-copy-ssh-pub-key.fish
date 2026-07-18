function 1password-copy-ssh-pub-key --description "Copy the selected 1Password SSH public key to a host"
    if test (count $argv) -ne 1
        echo "usage: 1password-copy-ssh-pub-key HOST" >&2
        return 2
    end

    set -l public_key (op-ssh-public-key)
    or return

    printf '%s\n' $public_key | command ssh "$argv[1]" 'mkdir ~/.ssh 2>/dev/null; cat >>~/.ssh/authorized_keys'
end
