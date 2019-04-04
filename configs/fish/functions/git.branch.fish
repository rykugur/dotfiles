function git.branch --description "Spits out the branch name of the current git repo, or returns status 1 (error) if we're not in a git branch"
  if git.is_branch
    echo (git status 2> /dev/null | head -n1 | awk "{print \$3}")
  else
    return 1
  end
end
