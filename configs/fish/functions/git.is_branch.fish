function git.is_branch --description "Returns true (0) if we're in a git repo, else false (1)"
  if [ (git status 2> /dev/null | head -n1 | awk "{print \$3}") ]
    return 0
  else
    return 1
  end
end
