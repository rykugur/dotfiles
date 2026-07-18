function cmd-paste
    switch (uname)
        case Linux
            wl-paste
        case Darwin
            pbpaste
        case '*'
            echo 'clipboard paste is unsupported on this platform' >&2
            return 1
    end
end
