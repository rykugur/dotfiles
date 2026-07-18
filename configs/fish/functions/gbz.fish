function gbz
    set -l branches (git branch)
    if test (count $argv) -gt 0
        set branches (string join \n $branches | command grep -i -- $argv[1])
    end

    set -l chosen_branch (string join \n $branches | fzf)
    if test -n "$chosen_branch"
        string trim -- (string replace '*' '' -- $chosen_branch)
    end
end
