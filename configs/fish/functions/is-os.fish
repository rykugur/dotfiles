function is-os --description "Test whether the current operating system matches a Nushell OS name"
    test (count $argv) -eq 1; or return 2

    set -l requested (string lower -- "$argv[1]")
    set -l actual (string lower -- (command uname))

    switch $requested
        case linux
            test "$actual" = linux
        case macos darwin
            test "$actual" = darwin
        case '*'
            return 1
    end
end
