function paste-multiline
    set -l cmd (cmd-paste | replace-multiline | string collect --no-trim-newlines)
    if test -z "$cmd"
        return 1
    end

    fish -c "$cmd"
end
