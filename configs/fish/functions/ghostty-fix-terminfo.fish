function ghostty-fix-terminfo --description "Install Ghostty terminfo on a remote host"
    if test (count $argv) -ne 1
        echo "usage: ghostty-fix-terminfo HOST" >&2
        return 2
    end

    command infocmp -x xterm-ghostty | command ssh "$argv[1]" -- tic -x -
end
