{
  dots = "cd ~/.dotfiles";
  ll = "ls -al";

  ga = "git add";
  gas = "git add (git status --short | grep -E '(AM|MM)' | awk '{print $2}')";
  gb = "git branch";
  gbD = "git branch -D";
  gbm = "git branch -m";
  gbr = "git branch -r";
  gc = "git commit";
  gca = "git commit --amend";
  gcm = "git commit -m";
  gco = "git checkout";
  gcob = "git checkout -b";
  gcu = ''rm -rf (git status --short | grep "??" | cut -d" " -f2)'';
  gd = "git diff";
  gds = "git diff --staged";
  gpl = "git pull";
  gps = "git push";
  gpsf = "git push --force";
  gpub = "git push -u origin (git symbolic-ref --short HEAD)";
  gr = "git reset";
  grb = "git rebase";
  grbc = "git rebase --continue";
  grh = "git reset HEAD";
  grhh = "git reset --hard HEAD";
  grv = "git remote -v";
  gss = "git status --short";
  gsub = "git submodule";

  gits = "cd ~/gits";
}
