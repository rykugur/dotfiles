function zellij-exists
    test (count $argv) -eq 1; or return 2

    set -l sessions (zellij ls | string replace -ra '\e\[[0-9;]*m' '' | string replace -r '\s.*$' '')
    contains -- "$argv[1]" $sessions
end
