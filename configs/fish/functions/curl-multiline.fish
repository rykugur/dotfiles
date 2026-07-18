function curl-multiline --description "Run an edited multiline curl command without shell evaluation"
    set -l content (edit-multiline | string collect)
    if test -z "$content"
        echo "No content passed in nor in clipboard, returning." >&2
        return 1
    end

    set -l command_line (printf '%s' "$content" | replace-multiline | string collect)
    set -l argument_line (string replace --regex '^curl[[:space:]]+' '' -- "$command_line")
    if test "$argument_line" = "$command_line"
        echo "The edited command must begin with curl." >&2
        return 2
    end

    set -l arguments
    set -l token
    set -l quote
    set -l escaped 0
    set -l token_started 0

    for character in (string match --all --regex '[\s\S]' -- "$argument_line")
        if test $escaped -eq 1
            set token "$token$character"
            set escaped 0
            set token_started 1
            continue
        end

        if test -n "$quote"
            if test "$quote" = "'"
                if test "$character" = "'"
                    set quote
                else
                    set token "$token$character"
                end
            else if test "$character" = '"'
                set quote
            else if test "$character" = '\\'
                set escaped 1
            else
                set token "$token$character"
            end
            set token_started 1
            continue
        end

        if string match --quiet --regex '^[[:space:]]$' -- "$character"
            if test $token_started -eq 1
                set --append arguments "$token"
                set token
                set token_started 0
            end
        else if test "$character" = "'"
            set quote "'"
            set token_started 1
        else if test "$character" = '"'
            set quote '"'
            set token_started 1
        else if test "$character" = '\\'
            set escaped 1
            set token_started 1
        else
            set token "$token$character"
            set token_started 1
        end
    end

    if test -n "$quote"; or test $escaped -eq 1
        echo "The edited curl command has an unmatched quote or escape." >&2
        return 2
    end

    if test $token_started -eq 1
        set --append arguments "$token"
    end

    if test (count $arguments) -eq 0
        echo "The edited curl command has no arguments." >&2
        return 2
    end

    command curl $arguments
end
