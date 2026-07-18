function zellij-exists
    test (count $argv) -eq 1; or return 2

    set -l sessions (zellij ls | string replace -ra '\e\[[0-9;]*m' '' | string replace -r '\s.*$' '')
    if string match --quiet --regex -- "$argv[1]" $sessions
        return 0
    else if test $status -eq 1
        return 1
    else
        return 2
    end
end
