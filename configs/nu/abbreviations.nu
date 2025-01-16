const docker = {
  dc: "docker compose"
  dcb: "docker compose build"
  dcl: "docker compose logs"
  dclf: "docker compose logs -f"
  dcr: "docker compose restart"
  dcu: "docker compose up"
  dcud: "docker compose up -d"
  dcd: "docker compose down"
  drit: "docker run -it"
  docker.clean: "docker rmi (docker images -f dangling=true -q)"
  lzd: "lazydocker"
}

const git = {
  ga: "git add"
  ga.: "git add ."
  gau: "git add -u"
  gb: "git branch"
  gbc: "git branch --contains"
  gbD: "git branch -D"
  gbm: "git branch -m"
  gbr: "git branch -r"
  gc: "git commit"
  gca: "git commit --amend"
  gcm: "git commit -m"
  gcmwip: "git commit -m wip"
  gco: "git checkout"
  gco.: "git checkout ."
  gcob: "git checkout -b"
  gcp: "git cherry-pick"
  gcy: "git commit -m (curl -s https://whatthecommit.com/index.txt)"
  gd: "git diff"
  gds: "git diff --staged"
  gf: "git fetch"
  gfp: "git fetch -p"
  gg: "git grep --color auto -n"
  ggi: "git grep --color auto -ni"
  gits: "cd $HOME/gits"
  gl: "git log"
  glo: "git log --oneline"
  glss: "git ls-files --stage"
  gpl: "git pull"
  gps: "git push"
  gpsf: "git push --force"
  gpssuo: "git push --set-upstream origin"
  gpls: "git pull; and git push"
  gpub: "git push -u origin (git.branch)"
  grb: "git rebase"
  grbc: "git rebase --continue"
  grpo: "git remote prune origin"
  gr: "git reset"
  grh: "git reset HEAD"
  grhh: "git reset --hard HEAD"
  grho: "git reset --hard origin/(git.branch)"
  grm: "git remote"
  grv: "git remote -v"
  gss: "git status --short"
  #gss: 'git status --short | lines | str trim | split column " "'
  gssg: "git status --short | grep"
  gsub: "git submodule"
  gw: "git worktree"
  gwa: "git worktree add"
  gwr: "git worktree remove"
  gwls: "git worktree list"
  turtles: "git commit -m \"it's turtles all the way down\""
}

const misc = {
  ### pacman
  pac: "pacman"
  pacs: "pacman -S"
  supac: "sudo pacman"
  supacr: "sudo pacman -R"
  supacrs: "sudo pacman -Rs"
  supacrcs: "sudo pacman -Rcs"
  supacs: "sudo pacman -S"
  supac.update: "sudo pacman -Sy archlinux-keyring; and sudo pacman -Su"
  ### systemctl
  sc: systemctl
  sc.list: "systemctl list-unit-files"
  sc.enabled: "systemctl list-unit-files | grep enabled"
  ssc: "sudo systemctl"
  ### tmux
  tm: "tmux"
  tmls: "tmux ls"
  tmf: "tmuxifier"
}

const nix = {
  nb: "nix build"
  ndb: "nix-build"

  nf: "nix flake"
  nfc: "nix flake check"
  nfu: "nix flake update"

  nr: "nix repl"
  nrn: "nix repl --file '<nixpkgs>'"
  nr.: "nix repl --file ."

  ns: "nix shell"
  nds: "nix-shell"
  ndsp: "nix-shell -p"

  snr: "sudo nixos-rebuild"
  snrs: "sudo nixos-rebuild switch"
  snrsf: "sudo nixos-rebuild switch --flake $env.DOTFILES_DIR"
}

const nush = {
  psw: "ps | where"
  pagi: "ps | where name =~"
}

const dev = {
  adb.reverse: "adb reverse tcp:8081 tcp:8081; adb reverse tcp:8080 tcp:8080"
  adb.start: "adb shell am start"
  adb.reset-perms: "adb shell pm reset-permissions"
  .gw: "./gradlew"
  agb: "ag --ignore-dir build --ignore-dir node_modules"
  agbt: "ag --ignore-dir build --ignore-dir node_modules --ignore-dir __tests__"
  fish.profile: "fish --profile-startup ./fish.profile -i -c exit"
  pyhttp: "python -m SimpleHTTPServer"
  pyjson: "python -m json.tool"
  cwd: "pwd | tr -d \"\n\" | cmd.copy"
  gri: "grep -i"
  grin: "grep -ni"
  grine: "grep -niRE"
  pwdc: "pwd | trim.newlines | cmd.copy"
  ssh.forcePass: "ssh -o PreferredAuthentications=password -o PubkeyAuthentication=no"
  sv: "sudo nvim"
  taill: "tail -Fn 999"

  pn: "pnpm"
}

const zellij = {
  za: "zellij attach"
  zj: "zellij"
}

export def get_abbreviations [] {
   # surely there's a better way to do this
  $dev | merge $nush | merge $misc | merge $nix | merge $git | merge $docker | merge $zellij
}
