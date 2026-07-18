function replace-multiline
    set -l content
    read --null content
    if test -z "$content"
        set content (cmd-paste | string collect --no-trim-newlines); or return
    end

    if test -z "$content"
        echo 'No content passed in nor in clipboard, returning.' >&2
        return 1
    end

    string replace --all --regex '\\\\[\r\n]+\s*' '' -- $content
end
