function gcoz
    set -l chosen_branch (gbz)
    if test -n "$chosen_branch"
        git checkout $chosen_branch
    end
end
