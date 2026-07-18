function edit-multiline
    set -l content
    read --null content
    if test -z "$content"
        set content (cmd-paste | string collect --no-trim-newlines); or return
    end

    if test -z "$content"
        echo 'No content passed in nor in clipboard, returning.' >&2
        return 1
    end

    set -l tmp_file (mktemp -t edit-multiline-XXXXXX); or return
    printf '%s' "$content" > $tmp_file
    command $EDITOR $tmp_file
    set -l editor_status $status
    cat $tmp_file
    rm -f -- $tmp_file
    return $editor_status
end
