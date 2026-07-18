function is-darwin --description "Test whether the current operating system is Darwin"
    test (count $argv) -eq 0; or return 2
    is-os macos
end
