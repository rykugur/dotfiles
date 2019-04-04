function git.is_dirty --description "Determines whether we're in a git repo or not, and if we are wether we're dirty. Return 1 if dirty, 0 otherwise"
  if git.is_branch
    if test -z (git status --short)
      return 0
    else
      return 1
    end
  end
end
