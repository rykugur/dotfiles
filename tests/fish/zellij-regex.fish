source configs/fish/functions/zellij-exists.fish
source configs/fish/functions/zellij-create-or-attach.fish

# Regression test for Task 6: invalid regex in zellij-exists
function test_zellij_exists_invalid_regex
    # Mock zellij ls to return a known session list
    function zellij
        if test "$argv[1]" = "ls"
            printf "session1\n"
        end
    end

    # Test invalid regex (unclosed bracket)
    zellij-exists "[" 2>/dev/null
    test $status -eq 2
    or begin
        echo "FAIL: zellij-exists should return 2 for invalid regex"
        return 1
    end

    # Test no-match (should return 1)
    zellij-exists "nonexistent" 2>/dev/null
    test $status -eq 1
    or begin
        echo "FAIL: zellij-exists should return 1 for no-match"
        return 1
    end

    # Test match (should return 0)
    zellij-exists "session1" 2>/dev/null
    test $status -eq 0
    or begin
        echo "FAIL: zellij-exists should return 0 for match"
        return 1
    end

    echo "PASS: zellij-exists regex handling"
    return 0
function test_zellij_create_or_attach_invalid_regex
    # Mock zellij ls, attach, and -s to record calls
    set -l zellij_calls
    function zellij
        set -a zellij_calls $argv
        if test "$argv[1]" = "ls"
            printf "session1\n"
        end
    end

    # Test invalid regex (unclosed bracket)
    zellij-create-or-attach "["
    test $status -eq 2
    or begin
        echo "FAIL: zellij-create-or-attach should return 2 for invalid regex"
        return 1
    end

    # Assert zellij attach and zellij -s were never called
    for call in $zellij_calls
        if test "$call[1]" = "attach" -o "$call[1]" = "-s" -o "$call[1]" = "--layout"
            echo "FAIL: zellij attach/-s/--layout was called for invalid regex: $call"
            return 1
        end
    end

    echo "PASS: zellij-create-or-attach invalid regex handling"
    return 0
end

# Run the tests
test_zellij_exists_invalid_regex; or exit 1
test_zellij_create_or_attach_invalid_regex; or exit 1
end