function git.branch --description "Spits out the branch name of the current git repo"
  echo (git status | head -n1 | awk "{print \$3}")
end
