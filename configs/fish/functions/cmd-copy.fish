function cmd-copy
    switch (uname)
        case Linux
            wl-copy
        case Darwin
            pbcopy
        case '*'
            echo 'clipboard copy is unsupported on this platform' >&2
            return 1
    end
end
