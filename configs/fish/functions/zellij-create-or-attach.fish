function zellij-create-or-attach
    test (count $argv) -ge 1; or return 2

    set -l session "$argv[1]"
    set -l layout
    switch (count $argv)
        case 1
        case 3
            test "$argv[2]" = --layout; or return 2
            set layout "$argv[3]"
        case '*'
            return 2
    end

    zellij-exists "$session"
    set -l exists_status $status
    switch $exists_status
        case 0
            zellij attach "$session"
            return $status
        case 1
            # No-op, proceed to create
        case '*'
            return $exists_status
    end

    if test -n "$layout"; and test -e "$layout"
        zellij --layout "$layout"
    else
        zellij -s "$session"
    end
end
