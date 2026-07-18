function __op-select-ssh-key
    if test (count $argv) -gt 0
        printf '%s\n' "$argv[1]"
        return
    end

    set -l selected (op item list --categories 'SSH Key' --format json \
        | jq -r '.[] | [.id, .title, .vault.name] | @tsv' \
        | fzf --delimiter=\t --with-nth=2,3)
    test -n "$selected"; or return 1
    string split \t -- "$selected" | head -n 1
end
