#

function git.compare --description "Compares two branches. Usage: git_compare_branches branch1 branch2"
  set -l argc (count $argv)
  set -l _usage "Usage: git_compare_branches branch1 branch2"

  if test $argc -eq 2
    git log --left-right --graph --cherry-pick --oneline $argv[1]..$argv[2]
  else
    echo $_usage
    return 1
  end
end
