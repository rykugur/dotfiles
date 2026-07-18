function is-linux --description "Test whether the current operating system is Linux"
    test (count $argv) -eq 0; or return 2
    is-os linux
end
