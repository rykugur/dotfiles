def --env dots [--edit (-e) --local (-l)] {
  if $local {
    let configFile = $env.LOCAL_CONFIG_FILE
    let dirName = $configFile | path dirname
    if (not ($configFile | path exists)) {
      mkdir $dirName
      touch $configFile
    }
    cd $dirName
    if ($edit) {
      ^($env.EDITOR) config.nu
    }
  } else {
    cd $env.DOTFILES_DIR
    if ($edit) {
      ^($env.EDITOR)
    }
  }
}

def is-os [os: string] {
  let os_lowercase = ($nu.os-info.name | str downcase)
  match $os {
    "linux" => ($os_lowercase == "linux"),
    "macos" => ($os_lowercase == "macos"),
    "darwin" => ($os_lowercase == "macos")
  }
}

def is-darwin [] {
  is-os "macos"
}

def is-macos [] {
  is-os "macos"
}

def is-linux [] {
  is-os "linux"
}

def "cmd.copy" [] {
  if (is-linux) {
    $in | wl-copy
  } else if (is-darwin) {
    $in | pbcopy
  }
}

def "cmd.paste" [] {
  if (is-linux) {
    wl-paste
  } else if (is-darwin) {
    pbpaste
  }
}

def replace-multiline [] {
  $in | str replace --all --regex '\\[\r\n]+\s*' ''
}

def paste-multiline-nu [] {
  let cmd = cmd.paste | replace-multiline
  nu -c $cmd
}

def "edit-multiline" [] {
  use std/log

  let content = $in | default (cmd.paste)
  if ($content | is-empty) {
    log error "No content passed in nor in clipboard, returning."
    return
  }

  let tmpFile = (mktemp -t edit-multiline-XXXXXX)

  $content | save -f $tmpFile
  hx $tmpFile

  let newContent = cat $tmpFile
  rm $tmpFile

  # send to stdout
  $newContent
}

def "ghostty fix terminfo" [host: string] {
  infocmp -x xterm-ghostty | ssh $host -- tic -x -
}

def "1password copy-ssh-pub-key" [host: string] {
  use 1password
  let key = 1password get-public-key

  ssh $host $"mkdir ~/.ssh 2> null; echo ($key) >> ~/.ssh/authorized_keys"
}

def "1password get-ssh-pub-key" [] {
  use 1password
  let key = 1password get-public-key

  $key
}

def "proxmox install helix" [host: string] {
  ssh $host $"curl -L https://shlink.ryk.sh/helix-deb | sh"
}

def --env "mo2installer" [] {
  cd ~/gits/modorganizer2-linux-installer/
}

$env.abbreviations = $env.abbreviations | merge {
  ### dev
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
  pwdc: "pwd | str trim | cmd.copy"
  ssh.forcePass: "ssh -o PreferredAuthentications=password -o PubkeyAuthentication=no"
  taill: "tail -Fn 999"
  pn: "pnpm"
  ### nushell
  psw: "ps | where"
  pagi: "ps | where name =~"
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
  ### zellij
  za: "zellij attach"
  zj: "zellij"
}
