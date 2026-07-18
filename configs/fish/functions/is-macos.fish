function is-macos --description "Test whether the current operating system is macOS"
    test (count $argv) -eq 0; or return 2
    is-os macos
end
