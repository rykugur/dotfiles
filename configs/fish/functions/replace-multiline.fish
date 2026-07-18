function replace-multiline
    set -l content
    if test -t 0
        set content (cmd-paste | string collect --no-trim-newlines); or return
    else
        read --null content
    end

    if test -z "$content"
        echo 'No content passed in nor in clipboard, returning.' >&2
        return 1
    end

    string replace --all --regex '\\\\[\r\n]+\s*' '' -- $content
end
