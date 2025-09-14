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

def --env y [...args] {
  let tmp = (mktemp -t "yazi-cwd.XXXXXX")
  yazi ...$args --cwd-file $tmp
  let cwd = (open $tmp)
  if $cwd != "" and $cwd != $env.PWD {
    cd $cwd
  }
  rm -fp $tmp
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
